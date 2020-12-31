local _, addon = ...
local QuestStatus = addon.QuestStatus
local CreateFrame = addon.G.CreateFrame
local GetCoinTextureString = addon.G.GetCoinTextureString
local asserttype = addon.asserttype

local widget = addon.CustomWidgets:NewWidget("QuestContent")

--[[
  Schema:
    Template: string
      The name of the section to inherit methods from (using MergeTable)
      Templates are applied recursively
    Build: function(self, parent) => frame
      Builds a single frame meant to extract and display some data about the quest.
      The frame returned from Build() will be Cleared and Populated for each quest that comes through.
      The frame will also have all the methods of the template (Build, Populate, Clear, etc.)
    Populate: function(self, quest)
      Modify the frame (self) to set some data about the quest.
    Clear: function(self)
      Remove any quest specific information from the frame (self)
    Condition: function(self, quest) => bool
      (optional) When should this frame be shown for a quest?
    Sections: table, array of section names
--]]

local styles = {
  Table = {
    margins = { l = 8, r = 8, t = 10, b = 0 },
    spacing = 12,
    width = nil,
  },
}

-- Track any data concerns that need to be resolved asynchronously
-- Format: { ["key1"] = anything, ["key2"] = nil }
local asyncConcerns = {}

local contentSectionTemplates = {
  -----------------------
  -- Template Sections --
  -----------------------
  ["Layout"] = {
    Build = nil,
    Sections = nil,
    Condition = nil,
    Populate = nil,
    Clear = nil,
  },
  ["Text"] = {
    Build = function(self, parent)
      local fs = parent:CreateFontString(addon:CreateGlobalName("QuestInfoFrame_"..self.Name.."_Text"), "BACKGROUND", self.Font)
      fs:SetJustifyH("LEFT")
      return fs
    end,
    Populate = function(self, quest)
      local text
      if type(self.Text) == "function" then
        text = self:Text(quest)
      elseif type(self.Text) == "string" then
        text = self.Text
      end

      self:SetText(text)
    end,
    Clear = function(self)
      self:SetText()
    end,
    Condition = function(self, quest)
      return self.Text
    end,
    Font = "QuestFont",
    Text = nil,
  },
  ["Header"] = {
    Template = "Text",
    Font = "QuestTitleFont",
  },
  ["Button"] = {
    Build = function(self, parent)
      local button = CreateFrame("Button", addon:CreateGlobalName("QuestInfoFrame_"..self.Name.."_Button"), parent, "UIPanelButtonTemplate")
      button:SetScript("OnClick", function()
        button:Handler(button._quest) -- quest must be assigned in populate method
      end)
      button:SetText(self.Text)
      -- button:SetWidth(self.Width) -- todo: can't set width because of automatic anchor, oh well

      return button
    end,
    Populate = function(self, quest)
      self._quest = quest
    end,
    Clear = function(self)
      self._quest = nil
    end,
    Text = "",
    -- Width = 80,
    Handler = function(self, quest)
      addon.Logger:Warn("No handler has been assigned to this button")
    end,
  },

  --------------------
  -- Basic Sections --
  --------------------
  ["NameHeader"] = {
    Template = "Header",
    Text = function(self, quest)
      return quest.name
    end,
  },
  ["DescriptionHeader"] = {
    Template = "Header",
    Text = "Description",
  },
  ["Description"] = {
    Template = "Text",
    Text = function(self, quest)
      return addon:PopulateText(quest.description or " ")
    end,
  },
  ["Completion"] = {
    Template = "Text",
    Text = function(self, quest)
      return addon:PopulateText(quest.completion or quest.description or " ")
    end,
  },
  ["ObjectivesHeader"] = {
    Template = "Header",
    Text = "Objectives",
  },
  ["Objectives"] = {
    Template = "Text",
    Text = function(self, quest)
      local objString = ""
      for _, obj in ipairs(quest.objectives) do
        objString = string.format("%s* %s\n", objString, addon:GetCheckpointDisplayText(obj, "quest"))
      end
      return objString
    end,
    Condition = function(self, quest)
      return quest.objectives
    end
  },
  ["RequirementsHeader"] = {
    Template = "Header",
    Text = "Requirements",
  },
  ["Requirements"] = {
    Template = "Text",
    Text = function(self, quest)
      local recString = ""
      if quest.required and quest.required.conditions then
        for k, v in pairs(quest.required.conditions) do
          recString = string.format("%s* %s: %s\n", recString, k, v)
        end
      end
      if quest.recommended and quest.recommended.conditions then
        for k, v in pairs(quest.recommended.conditions) do
          recString = string.format("%s* %s: %s (Recommended)\n", recString, k, v)
        end
      end
      return recString
    end,
    Condition = function(self, quest)
      return quest.required or quest.recommended
    end,
  },
  ["RewardHeader"] = {
    Template = "Header",
    Text = "Rewards",
  },
  ["RewardGiver"] = {
    Template = "Text",
    Text = function(self, quest)
      -- This is pretty hacky, but here goes:
      -- First, get the display text in the context of the rewards checkpoint
      local text = addon:GetCheckpointDisplayText(quest.rewards, "quest")
      -- ...but the %author and %giver values can only be populated in the context of the whole quest
      text = addon:PopulateText(text, quest)
      return text
    end,
    Condition = function(self, quest)
      return quest.rewards
    end,
  },
  ["RewardMoney"] = {
    Template = "Text",
    Text = function(self, quest)
      local coinText = GetCoinTextureString(quest.rewards.money)
      return "You will receive: "..coinText
    end,
    Condition = function(self, quest)
      return quest.rewards and quest.rewards.money
    end,
  },
  ["RewardItems"] = {
    Build = function(self, parent)
      return addon.CustomWidgets:CreateWidget("ItemRewardButtonPane", parent)
    end,
    Populate = function(self, quest)
      -- Always clear any existing selection on populate
      quest.rewards.selectedIndex = nil
      self:SetSelectedIndex() -- todo: Doesn't seem to work on Clear()?

      -- Enable item selection only if:
      --  1. The quest indicates that a reward should be selected, and
      --  2. The quest is in "Finished" status (as in, ready to turn in)
      if quest.rewards.choice and quest.status == QuestStatus.Finished then
        self:EnableSelection(true)
        self:OnSelectionChanged(function(index)
          quest.rewards.selectedIndex = index
        end)
      else
        self:EnableSelection(false)
      end

      local itemButtons = {}
      for _, item in ipairs(quest.rewards.items) do
        itemButtons[#itemButtons+1] = {
          itemId = item.itemId,
          count = item.quantity,
          -- usable = true -- todo: determine whether player can use this item?
        }

        -- Mark for concern: don't show content until all item names can be resolved
        local concern = string.format("Can't resolve name for item: %i", item.itemId)
        asyncConcerns[concern] = true
        addon:LookupItemAsync(item.itemId, function(i)
          asyncConcerns[concern] = nil -- Remove the concern once we can verify the item's name

          -- todo: this should be handled differently, will be a problem if other async concerns are added
          if addon:tlen(asyncConcerns) == 0 then
            self:SetItems(itemButtons)
            addon.AppEvents:Publish("QuestContentReady", quest)
          end
        end)
      end
    end,
    Condition = function(self, quest)
      return quest.rewards and quest.rewards.items
    end,
    Clear = function(self)
      self:SetItems()
      self:SetSelectedIndex()
    end,
  },
  ["StartConditionHeader"] = {
    Template = "Header",
    Text = "Getting Started",
  },
  ["StartCondition"] = {
    Template = "Text",
    Text = function(self, quest)
      return addon:GetCheckpointDisplayText(quest.start, "quest").."\n"
    end,
    Condition = function(self, quest)
      return quest.start and quest.start.conditions
    end,
  },
  ["CompleteConditionHeader"] = {
    Template = "Header",
    Text = "Finishing Up",
  },
  ["CompleteCondition"] = {
    Template = "Text",
    Text = function(self, quest)
      return addon:GetCheckpointDisplayText(quest.complete, "quest").."\n"
    end,
    Condition = function(self, quest)
      return quest.complete and quest.complete.conditions
    end,
  },
  ["TargetVerificationText"] = {
    Template = "Text",
    Text = "Check to see if the player you're targeting has completed this quest.",
  },
  ["TargetVerificationButton"] = {
    Template = "Button",
    Text = "Check Target Player",
  },
  ["PartyVerificationText"] = {
    Template = "Text",
    Text = "Check to see if your party members have completed this quest.",
  },
  ["PartyVerificationButton"] = {
    Template = "Button",
    Text = "Check Party",
  },
  ["RaidVerificationText"] = {
    Template = "Text",
    Text = "Check to see if your raid members have completed this quest.",
  },
  ["RaidVerificationButton"] = {
    Template = "Button",
    Text = "Check Raid",
  },

  -----------------------
  -- Compound Sections --
  -----------------------
  ["QuestStart"] = {
    Template = "Layout",
    Condition = "StartCondition",
    Sections = {
      "StartConditionHeader",
      "StartCondition",
    },
  },
  ["QuestComplete"] = {
    Template = "Layout",
    Condition = "CompleteCondition",
    Sections = {
      "CompleteConditionHeader",
      "CompleteCondition",
    },
  },
  ["QuestObjectives"] = {
    Template = "Layout",
    Condition = "Objectives",
    Sections = {
      "ObjectivesHeader",
      "Objectives",
    },
  },
  ["QuestRequirements"] = {
    Template = "Layout",
    Condition = "Requirements",
    Sections = {
      "RequirementsHeader",
      "Requirements",
    },
  },
  ["QuestRewards"] = {
    Template = "Layout",
    Condition = "RewardGiver",
    Sections = {
      "RewardHeader",
      "RewardMoney",
      "RewardGiver",
      "RewardItems",
    },
  },
  ["QuestVerification"] = {
    Template = "Layout",
    Sections = {
      "TargetVerificationText",
      "TargetVerificationButton",
      "PartyVerificationText",
      "PartyVerificationButton",
      "RaidVerificationText",
      "RaidVerificationButton",
    },
  },

  ------------------
  -- Mode layouts --
  ------------------
  ["NewQuest"] = {
    Template = "Layout",
    Sections = {
      "NameHeader",
      "Description",
      "QuestRequirements",
      "QuestStart",
      "QuestObjectives",
      "QuestRewards",
    },
  },
  ["FinishedQuest"] = {
    Template = "Layout",
    Sections = {
      "NameHeader",
      "Completion",
      "QuestComplete",
      "QuestRewards",
    },
  },
  ["ActiveQuest"] = {
    Template = "Layout",
    Sections = {
      "NameHeader",
      "Objectives",
      "DescriptionHeader",
      "Description",
      "QuestRewards",
    },
  },
  ["VerificationCheck"] = {
    Template = "Layout",
    Sections = {
      "NameHeader",
      "QuestVerification",
      "QuestRewards",
    },
  },
}

--- Recursively builds the section template with the specified name
--- @return table - the frame built by the merged template
local function buildTemplate(templateName)
  assert(templateName, "Unable to get content section template: no name provided")
  local template = contentSectionTemplates[templateName]
  assert(template, "No content section template exists with name: "..templateName)

  if template.Template then
    local innerTemplate = buildTemplate(template.Template)
    template = addon:MergeTable(innerTemplate, template)
  end

  if type(template.Condition) == "string" then
    -- If the Condition is just a section name, then go build that section
    -- and assign the resulting Condition function to the template
    local conditionTemplate = buildTemplate(template.Condition)
    template.Condition = conditionTemplate.Condition
  end

  -- Assign the template its own name based on its key in the table
  template.Name = templateName
  return template
end

--- Called once per session. Frames are saved for population when a quest comes in.
local function buildSections(contentFrame)
  local sections = {}

  for sectionName, _ in pairs(contentSectionTemplates) do
    local template = buildTemplate(sectionName)

    -- Build an instance of the section from the template
    local section
    if template.Build then
      -- Build the UI frame if the Build method is specified
      section = template:Build(contentFrame)
      asserttype(section, "table", "section", "Build")
      -- Clone the template methods ***and properties*** onto the created frame
      for pname, prop in pairs(template) do
        section[pname] = prop
      end
    else
      -- Otherwise, this is only a logical component with no UI frame, simply clone the template
      section = addon:CopyTable(template)
    end

    -- Assign the template's name to the section instance that it created
    section.Name = template.Name

    -- Save this built instance (frame) to be repopulated per quest
    sections[sectionName] = section
  end

  return sections
end

local function populateContentTable(tableLayout, quest, layoutName)
  local layout = tableLayout.questContentSections[layoutName]
  assert(layout, "No quest content section exists with name: "..layoutName)

  local doShow = true
  if layout.Condition then
    doShow = layout:Condition(quest)
  end

  if doShow then
    if layout.Sections then
      -- If the section defines a list of subsections, then populate each subsection and
      -- arrange them in the order listed.
      for _, sectionPointer in ipairs(layout.Sections) do
        if type(sectionPointer) == "string" then
          populateContentTable(tableLayout, quest, sectionPointer)
        elseif type(sectionPointer) == "table" then
          -- Section may specify a Condition under which any subsections are shown
          -- The Condition is simply a name of another section whose Condition function
          -- should be evaluated to determine whether or not the subsections should be shown
          local doShowSection = true
          if sectionPointer.Condition then
            local condSection = tableLayout.questContentSections[sectionPointer.Condition]
            assert(condSection, "Cannot evaluate Condition - no content section exists with name: "..sectionPointer.Condition)
            assert(condSection.Condition, "Cannot evaluate Condition - content section "..sectionPointer.Condition.." has no Condition function")
            doShowSection = condSection:Condition(quest)
          end

          if doShowSection then
            for _, sectionName in ipairs(sectionPointer.Sections) do
              populateContentTable(tableLayout, quest, sectionName)
            end
          end
        end
      end
    elseif layout.Populate then
      -- Otherwise, populate the section with quest content.
      -- Note that Sections and Populate are mutually exclusive.
      if layout.Populate then
        layout:Populate(quest)
      end

      -- Once populated for the quest, add the layout frame as a new row to the content table
      local row = tableLayout:AddRow()
      -- This is a 1-column table, so each layout fills the whole row
      layout:SetWidth(row:GetWidth() - 16) -- todo: hacking in a margin subtraction
      row:AddFrame(layout)
    end
  end
end

local methods = {
  ["SetQuestContent"] = function(self, quest, layoutName)
    asserttype(quest, "table", "quest", "SetQuestContent")
    asserttype(layoutName, "string", "layoutName", "SetQuestContent")

    self:ClearQuestContent()

    -- populateSections(self, self.questContentFrame, quest, layout.Sections)
    populateContentTable(self, quest, layoutName)

    if addon:tlen(asyncConcerns) == 0 then
      addon.AppEvents:Publish("QuestContentReady", quest)
    end
  end,
  ["ClearQuestContent"] = function(self)
    for _, section in ipairs(self.questContentSections) do
      -- Failsafe: Clear all frames, regardless of whether or not they're currently part of the table
      if section.Clear then
        -- Run custom Clear code for the section, if available
        section:Clear()
      end
    end

    self:ClearAllRows()
  end,
}

function widget:Create(parent)
  local tableLayout = addon.CustomWidgets:CreateWidget("TableLayout", parent, styles.Table)

  -- Save the content frame and built section frames
  -- in a place we can easily access them to populate them later
  tableLayout.questContentSections = buildSections(tableLayout)

  addon:ApplyMethods(tableLayout, methods)

  return tableLayout
end