local _, addon = ...
local CreateFrame, UIParent, UISpecialFrames = addon.G.CreateFrame, addon.G.UIParent, addon.G.UISpecialFrames
local QuestLog, QuestStatus = addon.QuestLog, addon.QuestStatus
local QuestCatalog, QuestCatalogStatus = addon.QuestCatalog, addon.QuestCatalogStatus
local StaticPopups = addon.StaticPopups
local localizer = addon.QuestScriptLocalizer

local pollingTimerInterval = 0.5 -- interval to poll for start/complete condition satisfaction, in seconds

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

local frameDefaultPos = {
  p1 = "TOPLEFT",
  p2 = "TOPLEFT",
  x = 0,
  y = -104,
  w = 384,
  h = 512,
}

local function acceptQuest(quest, sender)
  QuestLog:SaveWithStatus(quest, QuestStatus.Active)
  if QuestCatalog:FindByID(quest.questId) then
    QuestCatalog:SaveWithStatus(quest.questId, QuestCatalogStatus.Accepted)
  end
  if sender then
    addon.MessageEvents:Publish("QuestInviteAccepted", { distribution = "WHISPER", target = sender }, quest.questId)
  end
  addon:PlaySound("QuestAccepted")
  addon:ShowQuestInfoFrame(false)
  addon:ShowQuestLog(true)
end

local buttons = {
  ["Accept"] = {
    text = "Accept",
    width = 77,
    -- If the player meets requirements and the quest contains a start step, run start evaluation on an interval
    pollIf = function(quest) return addon.QuestEngine:EvaluateRequirements(quest) and quest.start end,
    enableIf = function(quest) return addon.QuestEngine:EvaluateRequirements(quest) and addon.QuestEngine:EvaluateStart(quest) end,
    action = function(quest, sender)
      local reqs = addon.QuestEngine:EvaluateRequirements(quest)
      if not reqs.pass then
        addon.Logger:Warn("You do not meet the requirements to start this quest.")
        return
      end
      if not addon.QuestEngine:EvaluateStart(quest) then
        addon.Logger:Warn("Unable to accept quest: start conditions are not met")
        return
      end
      local recs = addon.QuestEngine:EvaluateRecommendations(quest)
      if recs.pass then
        acceptQuest(quest, sender)
      else
        addon.StaticPopups:Show("StartQuestBelowRequirements", quest, recs):OnYes(function()
          acceptQuest(quest, sender)
        end)
      end
    end
  },
  ["Decline"] = {
    text = "Decline",
    width = 78,
    action = function(quest, sender)
      if sender then
        addon.MessageEvents:Publish("QuestInviteDeclined", { distribution = "WHISPER", target = sender }, quest.questId)
        QuestCatalog:SaveWithStatus(quest.questId, QuestCatalogStatus.Declined)
      end
      addon:ShowQuestInfoFrame(false)
    end
  },
  ["Complete"] = {
    text = "Complete Quest",
    width = 122, -- todo: lookup actual width
    -- If the quest contains a complete step, run completion evaluation on an interval
    pollIf = function(quest) return quest.complete end,
    enableIf = function(quest) return addon.QuestEngine:EvaluateComplete(quest) end,
    action = function(quest)
      if not addon.QuestEngine:EvaluateComplete(quest) then
        addon.Logger:Warn("Unable to complete quest: completion conditions are not met")
        return
      end
      QuestLog:SaveWithStatus(quest, QuestStatus.Completed)
      addon:PlaySound("QuestComplete")
      addon:ShowQuestInfoFrame(false)
    end
  },
  ["Abandon"] = {
    text = "Abandon Quest",
    width = 122, -- todo: lookup actual width
    action = function(quest)
      StaticPopups:Show("AbandonQuest", quest):OnYes(function()
        addon:ShowQuestInfoFrame(false)
      end)
    end
  },
  ["Share"] = {
    text = "Share Quest",
    width = 122, -- todo: lookup actual width
    action = function(quest)
      QuestLog:ShareQuest(quest.questId)
    end
  },
  ["Retry"] = {
    text = "Replay Quest",
    width = 122,
    action = function(quest)
      StaticPopups:Show("RetryQuest", quest):OnYes(function()
        addon:ShowQuestInfoFrame(false)
      end)
    end
  },
  ["Empty"] = {
    text = "",
    width = 78,
    action = function() end
  }
}

local function setButtonBehavior(btn, behavior, quest)
  -- Start by clearing the current button behavior
  btn._action = nil
  btn:SetText("")
  btn:Hide()
  if btn._pollTimerId then
    addon.Ace:CancelTimer(btn._pollTimerId)
    btn._pollTimerId = nil
  end

  -- If no behavior is supplied, do not show the button
  if not behavior then return end

  -- The default OnClick behavior is wired up to run this action
  btn._action = behavior.action
  btn:SetText(behavior.text)
  btn:SetWidth(behavior.width)

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
local frameModes = {
  ["NewQuest"] = {
    leftButton = buttons.Accept,
    rightButton = buttons.Decline,
    busy = function(frame, quest, sender)
      if sender then
        addon.Logger:Warn("%s invited you to a quest. View it in your Quest Catalog.", sender)
      else
        addon.Logger:Warn("Close this window before trying to view another quest.")
      end
    end,
    content = function(frame, quest, sender)
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
        if quest.required then
          for k, v in pairs(quest.required) do
            recString = string.format("%s* %s: %s\n", recString, k, v)
          end
        end
        if quest.recommended then
          for k, v in pairs(quest.recommended) do
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
    busy = function(frame, quest, sender)

    end,
    content = function(frame, quest, sender)
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
    busy = function(frame, quest, sender)

    end,
    content = function(frame, quest, sender)
      -- todo: real stuff here
      frame.article:GetFontString(2):SetText("You are currently on "..addon:Enquote(quest.name, '""'))
    end,
  },
  ["TerminatedQuest"] = {
    leftButton = buttons.Share,
    rightButton = buttons.Retry,
    busy = function(frame, quest, sender)

    end,
    content = function(frame, quest, sender)
      -- todo: real stuff here
      frame.article:GetFontString(2):SetText("Try again?")
    end,
  }
}

local frameMethods = {
  ["ShowQuest"] = function(self, quest, sender, mode)
    if self._shown and mode.busy then
      -- Another quest is already being interacted with
      -- If no "busy" function is specified, will proceed to draw content as normal
      mode.busy(self, quest, sender)
      return
    end

    self._quest = quest
    self._sender = sender
    self._shown = true

    self:ClearContent()

    mode.content(self, quest, sender)
    setButtonBehavior(self.leftButton, mode.leftButton, quest)
    setButtonBehavior(self.rightButton, mode.rightButton, quest)

    self:Show()
  end,
  ["CloseQuest"] = function(self)
    self._quest = nil
    self._sender = nil
    self._shown = nil

    setButtonBehavior(self.leftButton)
    setButtonBehavior(self.rightButton)

    self:Hide()
  end,
  ["ClearContent"] = function(self)
    self.titleFontString:SetText("")
    for _, fs in ipairs(self.article:GetFontStrings()) do
      fs:SetText("")
    end
  end,
  ["RefreshMode"] = function(self)
    local quest, sender = self._quest, self._sender
    addon:ShowQuestInfoFrame(false)
    addon:ShowQuestInfoFrame(true, quest, sender)
  end
}

local frameScripts = {
  ["OnShow"] = function(self)
    self._shown = true
    self.scrollFrame:SetVerticalScroll(0)
    addon:PlaySound("BookOpen")
  end,
  ["OnHide"] = function(self)
    self._shown = nil
    addon:PlaySound("BookClose")
  end,
  ["OnDragStart"] = function(self)
    self:StartMoving()
  end,
  ["OnDragStop"] = function(self)
    self:StopMovingOrSizing()
    addon:SaveWindowPosition(self, "QuestInfoFramePosition", frameDefaultPos)
  end,
  -- ["OnLoad"] = function() end,
  -- ["OnEvent"] = function() end,
}

local defaultStatusMode = "NewQuest"
local statusModeMap = {
  [QuestStatus.Active] = "ActiveQuest",
  [QuestStatus.Failed] = "TerminatedQuest",
  [QuestStatus.Abandoned] = "TerminatedQuest",
  [QuestStatus.Finished] = "FinishedQuest",
  [QuestStatus.Completed] = "TerminatedQuest",
}

local function buildQuestInfoFrame()
  local questFrame = CreateFrame("Frame", nil, UIParent)
  --questFrame:SetTopLevel(true)
  questFrame:SetMovable(true)
  questFrame:EnableMouse(true)
  questFrame:RegisterForDrag("LeftButton")
  questFrame:Hide()
  addon:LoadWindowPosition(questFrame, "QuestInfoFramePosition", frameDefaultPos)
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
        questFrameRightButton._action(questFrame._quest, questFrame._sender)
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
        questFrameLeftButton._action(questFrame._quest, questFrame._sender)
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

  -- Make closable with ESC
  local globalName = "PMQ_QuestInfoFrame"
  _G[globalName] = questFrame
  table.insert(UISpecialFrames, globalName)

  return questFrame
end

local questInfoFrame

function addon:ShowQuestInfoFrame(flag, quest, sender, modeName)
  if flag == nil then flag = true end
  if not questInfoFrame then
    questInfoFrame = buildQuestInfoFrame()
  end
  if flag then
    if not quest then
      addon.UILogger:Error("Unable to show QuestInfoFrame: no quest provided")
      return
    end

    -- Unless overridden, the mode that this frame displays in is determined directly by the quest's status
    if not modeName then
      if quest.status then
        modeName = statusModeMap[quest.status]
      else
        modeName = defaultStatusMode
      end
    end
    local mode = frameModes[modeName]
    if not mode then
      addon.UILogger:Warn("Unable to show QuestInfoFrame: %s is not a valid view mode", modeName)
      return
    end
    questInfoFrame:ShowQuest(quest, sender, mode)
  else
    questInfoFrame:CloseQuest()
  end
end
