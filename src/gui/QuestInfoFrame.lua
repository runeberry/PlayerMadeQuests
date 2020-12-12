local _, addon = ...
local CreateFrame = addon.G.CreateFrame
local QuestStatus = addon.QuestStatus

addon.QuestInfoFrame = nil -- Defined during lifecycle event

local pollTimers = {}
local pollingTimerInterval = 0.5 -- interval to poll for start/complete condition satisfaction, in seconds

local frameOptions = {
  movable = true,
  escapable = true,
  position = {
    p1 = "TOPLEFT",
    p2 = "TOPLEFT",
    x = 0,
    y = -104,
    w = 384,
    h = 512,
  }
}

local pageStyle = {
  margins = { 8, 8, 10, 0 }, -- bottom spacing doesn't work on a scroll frame
  spacing = 6
}

local textStyles = {
  ["header"] = {
    inheritsFrom = "QuestTitleFont",
    justifyH = "LEFT",
  },
  ["default"] = {
    inheritsFrom = "QuestFont",
    justifyH = "LEFT",
  }
}

local buttons = {
  ["Accept"] = {
    text = "Accept",
    width = 77,
    -- If the player meets requirements and the quest contains a start step, run start evaluation on an interval
    pollIf = function(quest) return addon.QuestEngine:EvaluateRequirements(quest) and quest.start end,
    enableIf = function(quest) return addon.QuestEngine:EvaluateRequirements(quest) and addon.QuestEngine:EvaluateStart(quest) end,
    action = function(quest)
      addon:AcceptQuest(quest)
    end
  },
  ["Decline"] = {
    text = "Decline",
    width = 78,
    action = function(quest)
      addon:DeclineQuest(quest)
    end
  },
  ["Complete"] = {
    text = "Complete Quest",
    width = 122, -- todo: lookup actual width
    -- If the quest contains a complete step, run completion evaluation on an interval
    pollIf = function(quest) return quest.complete end,
    enableIf = function(quest) return addon.QuestEngine:EvaluateComplete(quest) end,
    action = function(quest)
      addon:CompleteQuest(quest)
    end
  },
  ["Abandon"] = {
    text = "Abandon Quest",
    width = 122, -- todo: lookup actual width
    action = function(quest)
      addon:AbandonQuest(quest)
    end
  },
  ["Share"] = {
    text = "Share Quest",
    width = 122, -- todo: lookup actual width
    action = function(quest)
      addon:ShareQuest(quest)
    end
  },
  ["Restart"] = {
    text = "Restart Quest",
    width = 122,
    action = function(quest)
      addon:RestartQuest(quest)
    end
  },
  ["Empty"] = {
    text = "",
    width = 78,
    action = function() end
  }
}

local statusModeMap = {
  ["default"] = "NewQuest",
  [QuestStatus.Active] = "ActiveQuest",
  [QuestStatus.Failed] = "TerminatedQuest",
  [QuestStatus.Abandoned] = "TerminatedQuest",
  [QuestStatus.Finished] = "FinishedQuest",
  [QuestStatus.Completed] = "TerminatedQuest",
}

local function setButtonBehavior(btn, behavior, quest)
  -- Start by clearing the current button behavior
  btn._action = nil
  btn:SetText("")
  btn:Hide()
  if btn._pollTimerId then
    addon.Ace:CancelTimer(btn._pollTimerId)
    pollTimers[btn._pollTimerId] = nil
    btn._pollTimerId = nil
  end

  -- If no behavior is supplied, do not show the button
  if not behavior then return end

  -- The default OnClick behavior is wired up to run this action
  btn._action = behavior.action
  btn:SetText(behavior.text)
  btn:SetWidth(behavior.width)
  btn:SetEnabled(true)

  if quest then
    -- If the button is conditionally enabled, check that condition now
    if behavior.enableIf then
      btn:SetEnabled(behavior.enableIf(quest))
    end
    -- If a polling condition is met, then check the enable condition on an interval
    if behavior.pollIf and behavior.pollIf(quest) then
      btn._pollTimerId = addon.Ace:ScheduleRepeatingTimer(function()
        btn:SetEnabled(behavior.enableIf(quest))
      end, pollingTimerInterval)
      -- Keep track of all timers at the top-level so they can be disabled when the window is closed
      pollTimers[btn._pollTimerId] = true
    end
  end

  btn:Show()
end

local function drawQuestSections(questInfoFrame, quest, sections)
  -- Clear the content and remove it from the layout
  for _, section in pairs(questInfoFrame.sections) do
    section:Clear()
    section:Hide()
    section:ClearAllPoints()
  end

  local content = questInfoFrame.mainContent
  local prevSection

  -- Populate and anchor all sections in the order they were received
  for _, sname in ipairs(sections) do
    local section = questInfoFrame.sections[sname]
    assert(section, "QuestInfoFrame - no section exists with name: "..sname)

    section:Populate(quest)

    if not prevSection then
      -- First section, anchor it to the content frame
      section:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -10)
      section:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, -10)
    else
      -- 2nd and later sections, anchor to the previous section
      section:SetPoint("TOPLEFT", prevSection, "BOTTOMLEFT", 0, -6)
      section:SetPoint("TOPRIGHT", prevSection, "BOTTOMRIGHT", 0, -6)
    end

    section:Show()
    prevSection = section
  end
end

-- Various display configurations for this frame, depending on quest status, etc.
-- Properties:
--   title - text for the title bar at the top of the frame
--   sound - sound to play each time the frame is shown in this mode
--   leftButton/rightButton - the button behaviors of the bottom buttons (or nil to hide)
--   content - what to draw when the frame is shown in this mode
--   busy - what to draw when a request is recieved to show the frame, but it's already shown
--   clean - how to clean up the frame and leave an empty canvas for the next draw
local frameModes
frameModes = {
  ["NewQuest"] = {
    title = "[PMQ] Quest Info",
    sound = "BookWrite",
    leftButton = buttons.Accept,
    rightButton = buttons.Decline,
    busy = function(frame, quest)
      local sender = quest.metadata.giverName
      if sender then
        addon.Logger:Warn("%s invited you to a quest. View it in your Quest Catalog.", sender)
      else
        addon.Logger:Warn("Close this window before trying to view another quest.")
      end
    end,
    content = function(frame, quest)
      local sections = {}

      table.insert(sections, "NameHeader")
      table.insert(sections, "Description")

      if quest.required or quest.recommended then
        table.insert(sections, "RequirementsHeader")
        table.insert(sections, "Requirements")
      end

      if quest.start and quest.start.conditions then
        table.insert(sections, "StartObjectiveHeader")
        table.insert(sections, "StartObjective")
      end

      if quest.objectives then
        table.insert(sections, "ObjectivesHeader")
        table.insert(sections, "Objectives")
      end

      if quest.rewards then
        table.insert(sections, "RewardsHeader")
        table.insert(sections, "Rewards")
      end

      drawQuestSections(frame, quest, sections)
    end,
  },
  ["FinishedQuest"] = {
    title = "[PMQ] Quest Completion",
    leftButton = buttons.Empty,
    rightButton = buttons.Complete, -- todo: incorporate "Abandon" into this mode
    busy = function(frame, quest)

    end,
    content = function(frame, quest)
      local sections = {}

      table.insert(sections, "NameHeader")
      table.insert(sections, "Completion")

      if quest.complete and quest.complete.conditions then
        table.insert(sections, "CompleteObjectiveHeader")
        table.insert(sections, "CompleteObjective")
      end

      drawQuestSections(frame, quest, sections)
    end,
  },
  ["ActiveQuest"] = {
    title = "[PMQ] Quest Info",
    leftButton = buttons.Share,
    rightButton = buttons.Abandon,
    busy = function(frame, quest)

    end,
    content = function(frame, quest)
      local sections = {}

      table.insert(sections, "NameHeader")

      if quest.objectives then
        table.insert(sections, "Objectives")
      end

      table.insert(sections, "DescriptionHeader")
      table.insert(sections, "Description")

      -- todo: temp
      table.insert(sections, "RewardsHeader")
      table.insert(sections, "Rewards")

      drawQuestSections(frame, quest, sections)
    end,
  },
  ["TerminatedQuest"] = {
    title = "[PMQ] Quest Info",
    leftButton = buttons.Share,
    rightButton = buttons.Restart,
    busy = function(frame, quest)

    end,
    content = function(frame, quest)
      -- Using the same frame as NewQuest for now, may update this later
      frameModes["NewQuest"].content(frame, quest)
    end,
  }
}

local frameMethods = {
  ["ShowQuest"] = function(self, quest, modeName)
    addon:catch(function()
      local mode = frameModes[modeName or statusModeMap[quest.status or "default"]]

      if self._shown and mode.busy then
        -- Another quest is already being interacted with
        -- If no "busy" function is specified, will proceed to draw content as normal
        mode.busy(self, quest)
        return
      end

      self:ClearContent()

      local title = mode.title or ""
      self.titleFontString:SetText(title)

      mode.content(self, quest)
      setButtonBehavior(self.leftButton, mode.leftButton, quest)
      setButtonBehavior(self.rightButton, mode.rightButton, quest)

      self._quest = quest
      self._shown = true

      if mode.sound then
        addon:PlaySound(mode.sound)
      end

      self:Show()
    end)
  end,
  ["IsShowingQuest"] = function(self, quest)
    return self._shown and self._quest and self._quest.questId == quest.questId and true
  end,
  ["ClearContent"] = function(self)
    self.titleFontString:SetText("")
    -- for _, section in ipairs(self.sections) do

    -- end
  end,
  ["RefreshMode"] = function(self)
    local quest = self._quest
    addon.QuestInfoFrame:Hide()
    addon.QuestInfoFrame:ShowQuest(quest)
  end
}

local frameScripts = {
  ["OnShow"] = function(self)
    self._shown = true
    self.scrollFrame:SetVerticalScroll(0)
    addon:PlaySound("BookOpen")
  end,
  ["OnHide"] = function(self)
    self._quest = nil
    self._shown = nil

    setButtonBehavior(self.leftButton)
    setButtonBehavior(self.rightButton)

    -- Cancel any outstanding polling functions when the window is closed
    for pollTimerId in pairs(pollTimers) do
      addon.Ace:CancelTimer(pollTimerId)
    end
    pollTimers = {}

    addon:PlaySound("BookClose")
  end,
  -- ["OnLoad"] = function() end,
  -- ["OnEvent"] = function() end,
}

-- Builds a frame with an additional SetText method that can be used to update its underlying FontString
local function buildFontString(parent, fontTemplate)
  local fs = parent:CreateFontString(nil, "BACKGROUND", fontTemplate)
  fs:SetJustifyH("LEFT")
  return fs
end

-- Returns a content section with fixed text that does not change
-- based on the provided quest
local function buildStaticHeaderContent(text)
  return {
    Build = function(self, parent)
      local frame = buildFontString(parent, "QuestTitleFont")
      frame:SetText(text)
      return frame
    end,
    Populate = function() end,
    Clear = function() end
  }
end

local frameSections = {
  ---------------------
  -- Section Headers --
  ---------------------
  ["NameHeader"] = {
    Build = function(self, parent)
      return buildFontString(parent, "QuestTitleFont")
    end,
    Populate = function(self, quest)
      self:SetText(quest.name)
    end,
    Clear = function(self)
      self:SetText()
    end
  },
  ["DescriptionHeader"] = buildStaticHeaderContent("Description"),
  ["ObjectivesHeader"] = buildStaticHeaderContent("Objectives"),
  ["RequirementsHeader"] = buildStaticHeaderContent("Requirements"),
  ["RewardsHeader"] = buildStaticHeaderContent("Rewards"),
  ["StartObjectiveHeader"] = buildStaticHeaderContent("Getting Started"),
  ["CompleteObjectiveHeader"] = buildStaticHeaderContent("Finishing Up"),

  ---------------------
  -- Section content --
  ---------------------
  ["Description"] = {
    Build = function(self, parent)
      return buildFontString(parent, "QuestFont")
    end,
    Populate = function(self, quest)
      local description = quest.description or " "
      description = addon:PopulateText(description)
      self:SetText(description)
    end,
    Clear = function(self)
      self:SetText()
    end
  },
  ["Completion"] = {
    Build = function(self, parent)
      return buildFontString(parent, "QuestFont")
    end,
    Populate = function(self, quest)
      local completion = quest.completion or quest.description or " "
      completion = addon:PopulateText(completion)
      self:SetText(completion)
    end,
    Clear = function(self)
      self:SetText()
    end
  },
  ["Objectives"] = {
    Build = function(self, parent)
      return buildFontString(parent, "QuestFont")
    end,
    Populate = function(self, quest)
      if quest.objectives then
        local objString = ""
        for _, obj in ipairs(quest.objectives) do
          objString = string.format("%s* %s\n", objString, addon:GetCheckpointDisplayText(obj, "quest"))
        end
        -- objString = objString.."\n\n" -- Spacer for bottom margin
        self:SetText(objString)
      else
        self:SetText("\n")
      end
    end,
    Clear = function(self)
      self:SetText()
    end
  },
  ["Requirements"] = {
    Build = function(self, parent)
      return buildFontString(parent, "QuestFont")
    end,
    Populate = function(self, quest)
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
      self:SetText(recString)
    end,
    Clear = function(self)
      self:SetText()
    end
  },
  ["Rewards"] = {
    Build = function(self, parent)
      local itemRewardButtonPane = addon.CustomWidgets:CreateWidget("ItemRewardButtonPane", parent)

      -- todo: remove placeholder items
      itemRewardButtonPane:SetHeight(150)
      itemRewardButtonPane:SetItems({
        { itemId = 13444, count = 20 }, -- Major mana potion
        { itemId = 19019, count = 7, usable = false }, -- Thunderfury
        { itemId = 19019, count = 7, usable = false }, -- Thunderfury
        { itemId = 19019, count = 7, usable = false }, -- Thunderfury
      })

      return itemRewardButtonPane
    end,
    Populate = function(self, quest)
      -- todo
    end,
    Clear = function(self)
      -- todo
    end
  },
  ["StartObjective"] = {
    Build = function(self, parent)
      return buildFontString(parent, "QuestFont")
    end,
    Populate = function(self, quest)
      local text = addon:GetCheckpointDisplayText(quest.start, "quest")
      self:SetText(text.."\n")
    end,
    Clear = function(self)
      self:SetText()
    end
  },
  ["CompleteObjective"] = {
    Build = function(self, parent)
      return buildFontString(parent, "QuestFont")
    end,
    Populate = function(self, quest)
      local text = addon:GetCheckpointDisplayText(quest.start, "quest")
      self:SetText(text.."\n")
    end,
    Clear = function(self)
      self:SetText()
    end
  }
}

--- Builds the content of the quest frame that goes into the scroll frame
local function buildContentSections(parent)
  local sections = {}

  for sname, template in pairs(frameSections) do
    local section = template:Build(parent)

    -- Clone the template methods onto the created frame
    for fname, fn in pairs(template) do
      section[fname] = fn
    end

    sections[sname] = section
  end

  return sections
end

local function buildQuestInfoFrame()
  local questFrame = addon.CustomWidgets:CreateWidget("PopoutFrame", "QuestInfoFrame", frameOptions)
  --questFrame:SetTopLevel(true)

  questFrame:SetHitRectInsets(0, 30, 0, 70)
  for event, handler in pairs(frameScripts) do
    questFrame:SetScript(event, handler)
  end

  local questFramePortrait = questFrame:CreateTexture(nil, "ARTWORK")
  questFramePortrait:SetSize(60, 60)
  questFramePortrait:SetPoint("TOPLEFT", questFrame, "TOPLEFT", 7, -6)
  questFramePortrait:SetTexture("Interface\\QuestFrame\\UI-QuestLog-BookIcon")

  local questNpcNameFrame = CreateFrame("Frame", nil, questFrame)
  questNpcNameFrame:SetSize(300, 14)
  questNpcNameFrame:SetPoint("TOP", questFrame, "TOP", 0, -23)
  questNpcNameFrame:SetScript("OnLoad", function() end)

  local questFrameNpcNameText = questNpcNameFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
  questFrameNpcNameText:SetSize(235, 20)
  questFrameNpcNameText:SetPoint("CENTER", questNpcNameFrame, "CENTER")

  local questFrameCloseButton = CreateFrame("Button", nil, questFrame, "UIPanelCloseButton")
  questFrameCloseButton:SetPoint("CENTER", questFrame, "TOPRIGHT", -42, -31)

  local questFrameDetailPanel = CreateFrame("Frame", nil, questFrame, "QuestFramePanelTemplate")
  questFrameDetailPanel:SetScript("OnShow", function() end)
  questFrameDetailPanel:SetScript("OnHide", function() end)
  questFrameDetailPanel:SetScript("OnUpdate", function() end)
  --questFrameDetailPanel:Hide()

  local questFrameRightButton = CreateFrame("Button", nil, questFrameDetailPanel, "UIPanelButtonTemplate")
  questFrameRightButton:SetText("RIGHT_BTN") -- PLaceholder text
  questFrameRightButton:SetSize(1, 22) -- Placeholder width
  questFrameRightButton:SetPoint("BOTTOMRIGHT", questFrame, "BOTTOMRIGHT", -39, 72)
  questFrameRightButton:SetScript("OnClick", function()
    if questFrameRightButton._action then
      addon:catch(function()
        questFrameRightButton._action(questFrame._quest)
      end)
    else
      addon.UILogger:Warn("No action assigned to questFrameRightButton")
    end
  end)

  local questFrameLeftButton = CreateFrame("Button", nil, questFrameDetailPanel, "UIPanelButtonTemplate")
  questFrameLeftButton:SetText("LEFT_BTN") -- Placeholder text
  questFrameLeftButton:SetSize(1, 22) -- Placeholder width
  questFrameLeftButton:SetPoint("BOTTOMLEFT", questFrame, "BOTTOMLEFT", 23, 72)
  questFrameLeftButton:SetScript("OnClick", function()
    if questFrameLeftButton._action then
      addon:catch(function()
        questFrameLeftButton._action(questFrame._quest)
      end)
    else
      addon.UILogger:Warn("No action assigned to questFrameLeftButton")
    end
  end)

  local questDetailScrollFrame = CreateFrame("ScrollFrame", nil, questFrameDetailPanel, "QuestScrollFrameTemplate")
  questDetailScrollFrame:SetPoint("TOPLEFT", questFrameDetailPanel, "TOPLEFT", 22, -82)
  local questDetailScrollChildFrame = CreateFrame("Frame", nil, questDetailScrollFrame)
  questDetailScrollChildFrame:SetSize(300, 334)
  questDetailScrollChildFrame:SetPoint("TOPLEFT", questFrameDetailPanel, "TOPLEFT")
  questDetailScrollFrame:SetScrollChild(questDetailScrollChildFrame)

  local questDetailInfoFrame = CreateFrame("Frame", "PMQ_QuestInfoFrame_MainContent", questDetailScrollChildFrame)
  questDetailInfoFrame:SetSize(300, 100)
  questDetailInfoFrame:SetAllPoints(true)

  questFrame.scrollFrame = questDetailScrollFrame
  questFrame.titleFontString = questFrameNpcNameText
  questFrame.mainContent = questDetailInfoFrame
  questFrame.leftButton = questFrameLeftButton
  questFrame.rightButton = questFrameRightButton

  for name, method in pairs(frameMethods) do
    questFrame[name] = method
  end

  -- Can access individual sections by template name on this property
  questFrame.sections = buildContentSections(questFrame.mainContent)

  return questFrame
end

addon:OnGuiStart(function()
  addon.QuestInfoFrame = buildQuestInfoFrame()

  local function hide(quest)
    if addon.QuestInfoFrame:IsShowingQuest(quest) then
      addon.QuestInfoFrame:Hide()
    end
  end

  addon.AppEvents:Subscribe("QuestStarted", hide)
  addon.AppEvents:Subscribe("QuestAbandoned", hide)
  addon.AppEvents:Subscribe("QuestDeclined", hide)
  addon.AppEvents:Subscribe("QuestCompleted", hide)
end)