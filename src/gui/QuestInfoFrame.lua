local _, addon = ...
local CreateFrame, UIParent = addon.G.CreateFrame, addon.G.UIParent
local QuestLog, QuestStatus = addon.QuestLog, addon.QuestStatus
local QuestCatalog, QuestCatalogStatus = addon.QuestCatalog, addon.QuestCatalogStatus
local StaticPopups = addon.StaticPopups
local compiler = addon.QuestScriptCompiler


local refreshQuestFrame = function() end -- replaced with real function on build

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
    action = function(quest, sender)
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
    action = function(quest)
      QuestLog:SaveWithStatus(quest, QuestStatus.Finished)
      addon:PlaySound("QuestComplete")
      addon:ShowQuestInfoFrame(false)
    end
  },
  ["Abandon"] = {
    text = "Abandon Quest",
    width = 122, -- todo: lookup actual width
    action = function(quest)
      StaticPopups:Show("AbandonQuest", quest):OnYes(refreshQuestFrame)
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
      StaticPopups:Show("RetryQuest", quest):OnYes(refreshQuestFrame)
    end
  },
  ["Empty"] = {
    text = "",
    width = 78,
    action = function() end
  }
}

local function setButtonBehavior(btn, behavior)
  -- Start by clearing the current button behavior
  btn._action = nil
  btn:SetText("")
  btn:Hide()

  -- If no behavior is supplied, do not show the button
  if not behavior then return end

  -- The default OnClick behavior is wired up to run this action
  btn._action = behavior.action
  btn:SetText(behavior.text)
  btn:SetWidth(behavior.width)
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
        addon.Logger:Warn(sender, "invited you to a quest. View it in your Quest Catalog.")
      else
        addon.Logger:Warn("Accept or decline this quest before trying to view another one.")
      end
    end,
    content = function(frame, quest, sender)
      frame.titleFontString:SetText("[PMQ] Quest Info")

      frame.article:GetFontString(1):SetText(quest.name)
      frame.article:GetFontString(2):SetText(quest.description or " ")
      frame.article:GetFontString(3):SetText("Quest Objectives")

      if quest.objectives then
        local objString = ""
        for _, obj in ipairs(quest.objectives) do
          objString = objString.."* "..compiler:GetDisplayText(obj, "quest").."\n"
        end
        objString = objString.."\n\n" -- Spacer for bottom margin
        frame.article:GetFontString(4):SetText(objString)
      else
        frame.article:GetFontString(4):SetText("\n")
      end

      addon:PlaySound("BookWrite")
    end,
  },
  ["CompletedQuest"] = {
    leftButton = buttons.Empty,
    rightButton = buttons.Complete, -- todo: incorporate "Abandon" into this mode
    busy = function(frame, quest, sender)

    end,
    content = function(frame, quest, sender)
      -- todo: real stuff here
      frame.article:GetFontString(2):SetText("You completed "..addon:Enquote(quest.name, '""!'))
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
    setButtonBehavior(self.leftButton, mode.leftButton)
    setButtonBehavior(self.rightButton, mode.rightButton)

    self:Show()
  end,
  ["CloseQuest"] = function(self)
    self._quest = nil
    self._sender = nil
    self._shown = nil

    setButtonBehavior(self.leftButton, nil)
    setButtonBehavior(self.rightButton, nil)

    self:Hide()
  end,
  ["ClearContent"] = function(self)
    self.titleFontString:SetText("")
    self.article:GetFontString(1):SetText("")
    self.article:GetFontString(2):SetText("")
    self.article:GetFontString(3):SetText("")
    self.article:GetFontString(4):SetText("")
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
  -- ["OnLoad"] = function() end,
  -- ["OnEvent"] = function() end,
}

local defaultStatusMode = "NewQuest"
local statusModeMap = {
  [QuestStatus.Active] = "ActiveQuest",
  [QuestStatus.Failed] = "TerminatedQuest",
  [QuestStatus.Abandoned] = "TerminatedQuest",
  [QuestStatus.Completed] = "CompletedQuest",
  [QuestStatus.Finished] = "TerminatedQuest",
  [QuestStatus.Archived] = "TerminatedQuest",
}

local function buildQuestInfoFrame()
  local questFrame = CreateFrame("Frame", nil, UIParent)
  --questFrame:SetTopLevel(true)
  questFrame:SetMovable(true)
  questFrame:EnableMouse(true)
  questFrame:Hide()
  questFrame:SetSize(384, 512)
  questFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, -104)
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
  -- questDetailScrollFrame:SetAllPoints(true)
  local questDetailScrollChildFrame = CreateFrame("Frame", nil, questDetailScrollFrame)
  questDetailScrollChildFrame:SetSize(300, 334)
  questDetailScrollChildFrame:SetPoint("TOPLEFT", questFrameDetailPanel, "TOPLEFT")
  questDetailScrollFrame:SetScrollChild(questDetailScrollChildFrame)

  local questDetailInfoFrame = CreateFrame("Frame", nil, questDetailScrollChildFrame)
  questDetailInfoFrame:SetSize(300, 100)
  questDetailInfoFrame:SetAllPoints(true)

  local article = addon.CustomWidgets:CreateWidget("ArticleText", questDetailInfoFrame)
  article:SetPageStyle(pageStyle)
  for name, style in pairs(textStyles) do
    article:SetTextStyle(name, style)
  end

  -- Placeholder text, the real values get popped in when a quest is received
  article:AddText("HEADER_1", "header")
  article:AddText("BODY_1")
  article:AddText("HEADER_2", "header")
  article:AddText("BODY_2")
  article:Assemble()

  refreshQuestFrame = function()
    questFrame:RefreshMode()
  end

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
      addon.UILogger:Warn("Unable to show QuestInfoFrame:", modeName, "is not a valid view mode")
      return
    end
    questInfoFrame:ShowQuest(quest, sender, mode)
  else
    questInfoFrame:CloseQuest()
  end
end
