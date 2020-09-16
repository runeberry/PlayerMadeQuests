local _, addon = ...
local CreateFrame = addon.G.CreateFrame
local QuestStatus = addon.QuestStatus
local QuestCatalog, QuestCatalogSource = addon.QuestCatalog, addon.QuestCatalogSource
local localizer = addon.QuestScriptLocalizer

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
  ["Retry"] = {
    text = "Replay Quest",
    width = 122,
    action = function(quest)
      addon:RetryQuest(quest)
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

-- Various display configurations for this frame, depending on quest status, etc.
-- Properties:
--   leftButton/rightButton - the button behaviors of the bottom buttons (or nil to hide)
--   content - what to draw when the frame is shown in this mode
--   busy - what to draw when a request is recieved to show the frame, but it's already shown
--   clean - how to clean up the frame and leave an empty canvas for the next draw
local frameModes
frameModes = {
  ["NewQuest"] = {
    leftButton = buttons.Accept,
    rightButton = buttons.Decline,
    busy = function(frame, quest)
      local catalogItem = QuestCatalog:FindByID(quest.questId)
      local sender = catalogItem.from and catalogItem.from.name
      if sender and catalogItem.from.source == QuestCatalogSource.Shared then
        addon.Logger:Warn("%s invited you to a quest. View it in your Quest Catalog.", sender)
      else
        addon.Logger:Warn("Close this window before trying to view another quest.")
      end
    end,
    content = function(frame, quest)
      frame.titleFontString:SetText("[PMQ] Quest Info")

      local fs = frame.article:GetFontStrings()

      -- Quest name & description
      fs[1]:SetText(quest.name)
      fs[2]:SetText(quest.description or " ")

      local index = 3

      -- Requirements & recommendations
      if quest.required or quest.recommended then
        fs[index]:SetText("Requirements")
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
        fs[index+1]:SetText(recString)
        index = index + 2
      end

      -- Starting condition
      if quest.start and quest.start.conditions then
        fs[index]:SetText("Getting Started")
        fs[index+1]:SetText(localizer:GetDisplayText(quest.start, "quest").."\n")
        index = index + 2
      end

      -- Quest objectives
      fs[index]:SetText("Quest Objectives")
      if quest.objectives then
        local objString = ""
        for _, obj in ipairs(quest.objectives) do
          objString = string.format("%s* %s\n", objString, localizer:GetDisplayText(obj, "quest"))
        end
        objString = objString.."\n\n" -- Spacer for bottom margin
        fs[index+1]:SetText(objString)
      else
        fs[index+1]:SetText("\n")
      end

      addon:PlaySound("BookWrite")
    end,
  },
  ["FinishedQuest"] = {
    leftButton = buttons.Empty,
    rightButton = buttons.Complete, -- todo: incorporate "Abandon" into this mode
    busy = function(frame, quest)

    end,
    content = function(frame, quest)
      frame.titleFontString:SetText("[PMQ] Quest Completion")

      local fs = frame.article:GetFontStrings()

      -- Quest name & description
      fs[1]:SetText(quest.name)
      fs[2]:SetText(quest.completion or quest.description or " ")

      -- Completion objectives
      if quest.complete and quest.complete.conditions then
        fs[3]:SetText("Finishing Up")
        fs[4]:SetText(localizer:GetDisplayText(quest.complete, "quest").."\n")
      end
    end,
  },
  ["ActiveQuest"] = {
    leftButton = buttons.Share,
    rightButton = buttons.Abandon,
    busy = function(frame, quest)

    end,
    content = function(frame, quest)
      frame.titleFontString:SetText("[PMQ] Quest Info")

      local fs = frame.article:GetFontStrings()

      -- Quest name & objectives
      fs[1]:SetText(quest.name)
      if quest.objectives then
        local objString = ""
        for _, obj in ipairs(quest.objectives) do
          objString = string.format("%s* %s\n", objString, localizer:GetDisplayText(obj, "quest"))
        end
        fs[2]:SetText(objString)
      else
        fs[2]:SetText("\n")
      end

      -- Quest Description
      fs[3]:SetText("Description")
      fs[4]:SetText((quest.description or " ").."\n\n") -- Space for bottom margin
    end,
  },
  ["TerminatedQuest"] = {
    leftButton = buttons.Share,
    rightButton = buttons.Retry,
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
    local mode = frameModes[modeName or statusModeMap[quest.status or "default"]]

    if self._shown and mode.busy then
      -- Another quest is already being interacted with
      -- If no "busy" function is specified, will proceed to draw content as normal
      mode.busy(self, quest)
      return
    end

    self:ClearContent()

    mode.content(self, quest)
    setButtonBehavior(self.leftButton, mode.leftButton, quest)
    setButtonBehavior(self.rightButton, mode.rightButton, quest)

    self._quest = quest
    self._shown = true

    self:Show()
  end,
  ["ClearContent"] = function(self)
    self.titleFontString:SetText("")
    for _, fs in ipairs(self.article:GetFontStrings()) do
      fs:SetText("")
    end
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

  local questDetailInfoFrame = CreateFrame("Frame", nil, questDetailScrollChildFrame)
  questDetailInfoFrame:SetSize(300, 100)
  questDetailInfoFrame:SetAllPoints(true)

  local article = addon.CustomWidgets:CreateWidget("ArticleText", questDetailInfoFrame)
  article:SetAllPoints(true)
  article:SetPageStyle(pageStyle)
  for name, style in pairs(textStyles) do
    article:SetTextStyle(name, style)
  end

  -- Placeholder text, the real values get popped in when a quest is received
  article:AddText("HEADER_1", "header")
  article:AddText("BODY_1")
  article:AddText("HEADER_2", "header")
  article:AddText("BODY_2")
  article:AddText("HEADER_3", "header")
  article:AddText("BODY_3")
  article:AddText("HEADER_4", "header")
  article:AddText("BODY_4")
  article:Assemble()

  questFrame.scrollFrame = questDetailScrollFrame
  questFrame.titleFontString = questFrameNpcNameText
  questFrame.article = article
  questFrame.leftButton = questFrameLeftButton
  questFrame.rightButton = questFrameRightButton

  for name, method in pairs(frameMethods) do
    questFrame[name] = method
  end

  return questFrame
end

addon:OnGuiStart(function()
  addon.QuestInfoFrame = buildQuestInfoFrame()
end)