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

-- Various display configurations for this frame, depending on quest status, etc.
-- Properties:
--   title - text for the title bar at the top of the frame
--   sound - sound to play each time the frame is shown in this mode
--   leftButton/rightButton - the button behaviors of the bottom buttons (or nil to hide)
--   layout - quest content layout names in the order that they should be displayed
--   content - what to draw when the frame is shown in this mode
--   busy - what to draw when a request is recieved to show the frame, but it's already shown
--   clean - how to clean up the frame and leave an empty canvas for the next draw
local frameModes
frameModes = {
  ["NewQuest"] = {
    title = "[PMQ] Quest Info",
    layout = "NewQuest",
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
  },
  ["FinishedQuest"] = {
    title = "[PMQ] Quest Completion",
    layout = "FinishedQuest",
    leftButton = buttons.Empty,
    rightButton = buttons.Complete, -- todo: incorporate "Abandon" into this mode
    busy = function(frame, quest)

    end,
  },
  ["ActiveQuest"] = {
    title = "[PMQ] Quest Info",
    layout = "ActiveQuest",
    leftButton = buttons.Share,
    rightButton = buttons.Abandon,
    busy = function(frame, quest)

    end,
  },
  ["TerminatedQuest"] = {
    title = "[PMQ] Quest Info",
    layout = "NewQuest",
    leftButton = buttons.Share,
    rightButton = buttons.Restart,
    busy = function(frame, quest)

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

      -- See QuestInfoFrameContent.lua for details
      self.questContent:SetQuestContent(quest, mode.layout)

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
  local frame = addon.CustomWidgets:CreateWidget("PopoutFrame", "QuestInfoFrame", frameOptions)
  --questFrame:SetTopLevel(true)

  frame:SetHitRectInsets(0, 30, 0, 70)
  for event, handler in pairs(frameScripts) do
    frame:SetScript(event, handler)
  end

  local questFramePortrait = frame:CreateTexture(nil, "ARTWORK")
  questFramePortrait:SetSize(60, 60)
  questFramePortrait:SetPoint("TOPLEFT", frame, "TOPLEFT", 7, -6)
  questFramePortrait:SetTexture("Interface\\QuestFrame\\UI-QuestLog-BookIcon")

  local questNpcNameFrame = CreateFrame("Frame", nil, frame)
  questNpcNameFrame:SetSize(300, 14)
  questNpcNameFrame:SetPoint("TOP", frame, "TOP", 0, -23)
  questNpcNameFrame:SetScript("OnLoad", function() end)

  local questFrameNpcNameText = questNpcNameFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
  questFrameNpcNameText:SetSize(235, 20)
  questFrameNpcNameText:SetPoint("CENTER", questNpcNameFrame, "CENTER")

  local questFrameCloseButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  questFrameCloseButton:SetPoint("CENTER", frame, "TOPRIGHT", -42, -31)

  local questFrameDetailPanel = CreateFrame("Frame", nil, frame, "QuestFramePanelTemplate")
  questFrameDetailPanel:SetScript("OnShow", function() end)
  questFrameDetailPanel:SetScript("OnHide", function() end)
  questFrameDetailPanel:SetScript("OnUpdate", function() end)
  --questFrameDetailPanel:Hide()

  local questFrameRightButton = CreateFrame("Button", nil, questFrameDetailPanel, "UIPanelButtonTemplate")
  questFrameRightButton:SetText("RIGHT_BTN") -- PLaceholder text
  questFrameRightButton:SetSize(1, 22) -- Placeholder width
  questFrameRightButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -39, 72)
  questFrameRightButton:SetScript("OnClick", function()
    if questFrameRightButton._action then
      addon:catch(function()
        questFrameRightButton._action(frame._quest)
      end)
    else
      addon.UILogger:Warn("No action assigned to questFrameRightButton")
    end
  end)

  local questFrameLeftButton = CreateFrame("Button", nil, questFrameDetailPanel, "UIPanelButtonTemplate")
  questFrameLeftButton:SetText("LEFT_BTN") -- Placeholder text
  questFrameLeftButton:SetSize(1, 22) -- Placeholder width
  questFrameLeftButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 23, 72)
  questFrameLeftButton:SetScript("OnClick", function()
    if questFrameLeftButton._action then
      addon:catch(function()
        questFrameLeftButton._action(frame._quest)
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

  -- local questDetailInfoFrame = addon.CustomWidgets:CreateWidget("TableLayout", questDetailScrollChildFrame)
  -- local questDetailInfoFrame = CreateFrame("Frame", "PMQ_QuestInfoFrame_MainContent", questDetailScrollChildFrame)
  -- questDetailInfoFrame:SetSize(300, 100)
  -- questDetailInfoFrame:SetAllPoints(true)

  -- The contents of the main reading frame are pretty complex so the code
  -- for that was moved to a separate widget
  local questContent = addon.CustomWidgets:CreateWidget("QuestContent", questDetailScrollChildFrame)
  questContent:SetAllPoints(true)

  frame.scrollFrame = questDetailScrollFrame
  frame.titleFontString = questFrameNpcNameText
  frame.leftButton = questFrameLeftButton
  frame.rightButton = questFrameRightButton
  frame.questContent = questContent

  for name, method in pairs(frameMethods) do
    frame[name] = method
  end



  return frame
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