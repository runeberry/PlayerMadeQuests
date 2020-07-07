local _, addon = ...
local CreateFrame, UIParent = addon.G.CreateFrame, addon.G.UIParent
local compiler = addon.QuestScriptCompiler

local questInfoFrame
local currentQuest -- The quest being proposed in the window
local currentQuestSender -- The player who sent the currently proposed quest

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
    action = function()
      if not currentQuest then
        addon.Logger:Warn("There is no quest to accept!")
        return
      end

      addon.QuestLog:SaveWithStatus(currentQuest, addon.QuestStatus.Active)

      if currentQuestSender then
        addon.MessageEvents:Publish("QuestInviteAccepted", { distribution = "WHISPER", target = currentQuestSender }, currentQuest.questId)
      end

      addon:ShowQuestInfoFrame(false)

      addon:PlaySound("QuestAccepted")
      addon:ShowQuestLog(true)
    end
  },
  ["Decline"] = {
    text = "Decline",
    action = function()
      if currentQuestSender then
        addon.MessageEvents:Publish("QuestInviteDeclined", { distribution = "WHISPER", target = currentQuestSender }, currentQuest.questId)
        addon.QuestLog:SaveWithStatus(currentQuest, addon.QuestStatus.Declined)
      end
      addon:ShowQuestInfoFrame(false)
    end
  }
}

local function setButtonBehavior(btn, behaviorId)
  -- Start by clearing the current button behavior
  btn._action = nil
  btn:SetText("")
  btn:Hide()

  if not behaviorId then return end

  local behavior = buttons[behaviorId]
  if not behavior then
    addon.UILogger:Warn(behaviorId, "is not a valid button behavior for QuestInfoFrame")
    return
  end

  -- The default OnClick behavior is wired up to run this action
  btn._action = behavior.action
  btn:SetText(behavior.text)
  btn:Show()
end

local frameMethods = {
  ["SetTitle"] = function(self, str)
    self.titleFontString:SetText(str)
  end,
  ["SetContent"] = function(self, quest)
    local fsQuestName = self.article:GetFontString(1)
    local fsQuestDescription = self.article:GetFontString(2)
    local fsQuestObjectives = self.article:GetFontString(4)

    fsQuestName:SetText(quest.name)
    fsQuestDescription:SetText(quest.description or " ")

    if quest.objectives then
      local objString = ""
      for _, obj in ipairs(quest.objectives) do
        objString = objString.."* "..compiler:GetDisplayText(obj, "quest").."\n"
      end
      fsQuestObjectives:SetText(objString)
    else
      fsQuestObjectives:SetText("\n")
    end
  end,
  ["SetButtons"] = function(self, behaviorIdLeft, behaviorIdRight)
    setButtonBehavior(self.leftButton, behaviorIdLeft)
    setButtonBehavior(self.rightButton, behaviorIdRight)
  end
}

local frameScripts = {
  ["OnShow"] = function(self)
    self.scrollFrame:SetVerticalScroll(0)
    addon:PlaySound("BookOpen")
  end,
  ["OnHide"] = function(self)
    currentQuest = nil
    currentQuestSender = nil
    addon:PlaySound("BookClose")
  end,
  -- ["OnLoad"] = function() end,
  -- ["OnEvent"] = function() end,
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
  questFrameRightButton:SetSize(78, 22)
  questFrameRightButton:SetPoint("BOTTOMRIGHT", questFrame, "BOTTOMRIGHT", -39, 72)
  questFrameRightButton:SetScript("OnClick", function()
    if questFrameRightButton._action then
      questFrameRightButton._action()
    else
      addon.UILogger:Warn("No action assigned to questFrameRightButton")
    end
  end)

  local questFrameLeftButton = CreateFrame("Button", nil, questFrameDetailPanel, "UIPanelButtonTemplate")
  questFrameLeftButton:SetText("LEFT_BTN") -- Placeholder text
  questFrameLeftButton:SetSize(77, 22)
  questFrameLeftButton:SetPoint("BOTTOMLEFT", questFrame, "BOTTOMLEFT", 23, 72)
  questFrameLeftButton:SetScript("OnClick", function()
    if questFrameLeftButton._action then
      questFrameLeftButton._action()
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
  article:AddText("QUEST_NAME", "header")
  article:AddText("QUEST_DESCRIPTION")
  article:AddText("Quest Objectives", "header") -- Except this one, that's a real header
  article:AddText("QUEST_OBJECTIVES_TEXT")
  article:AddText("\n\n") -- Spacer for bottom margin
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

function addon:ShowQuestInfoFrame(flag, quest, sender)
  if flag == nil then flag = true end
  if flag then
    if currentQuest then
      -- Another quest is already being interacted with
      if sender then
        addon.Logger:Warn(sender, "invited you to a quest. View it in the Quest Log menu.")
      else
        addon.Logger:Warn("Accept or decline this quest before trying to view another one.")
      end
      return
    end
    if not questInfoFrame then
      questInfoFrame = buildQuestInfoFrame()
    end
    if quest then
      questInfoFrame:SetTitle("[PMQ] Quest Info")
      questInfoFrame:SetContent(quest)
      -- questInfoFrame.scrollFrame:SetVerticalScroll(0)
      currentQuest = quest
      currentQuestSender = sender
      questInfoFrame:Show()
      questInfoFrame:SetButtons("Accept", "Decline")
      addon:PlaySound("BookWrite")
    end
  else
    if questInfoFrame then
      currentQuest = nil
      currentQuestSender = nil
      questInfoFrame:SetButtons(nil, nil)
      questInfoFrame:Hide()
    end
  end
end

-- This expects a fully compiled and built quest
local function handleQuestInvite(quest, sender)
  addon:ShowQuestInfoFrame(true, quest, sender)
end

addon:onload(function()
  addon.AppEvents:Subscribe("QuestInvite", handleQuestInvite)
end)