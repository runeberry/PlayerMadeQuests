local _, addon = ...
local CreateFrame, UIParent = addon.G.CreateFrame, addon.G.UIParent

local questInviteFrame
local currentQuest -- The quest being proposed in the window

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

local pageStyle = {
  margins = { 8, 8, 10, 0 }, -- bottom spacing doesn't work on a scroll frame
  spacing = 6
}

local function qf_SetTitle(self, str)
  self.titleFontString:SetText(str)
end

local function qf_SetContent(self, quest)
  local fsQuestName = self.article:GetFontString(1)
  local fsQuestDescription = self.article:GetFontString(2)
  local fsQuestObjectives = self.article:GetFontString(4)

  fsQuestName:SetText(quest.name)
  fsQuestDescription:SetText(quest.description or " ")

  if quest.objectives then
    local objString = ""
    for _, obj in ipairs(quest.objectives) do
      objString = objString.."* "..obj:GetDisplayText().."\n"
    end
    fsQuestObjectives:SetText(objString)
  else
    fsQuestObjectives:SetText("\n")
  end

end

local function qf_OnShow(self)
  self.scrollFrame:SetVerticalScroll(0)
end

local function qf_OnHide(self)
  currentQuest = nil
end

local function acceptButton_OnClick()
  if not currentQuest then
    addon.Logger:Warn("There is no quest to accept!")
    return
  end
  addon.QuestLog:AcceptQuest(currentQuest)
  addon:ShowQuestInviteFrame(false)
end

local function declineButton_OnClick()
  addon:ShowQuestInviteFrame(false)
end

local function buildQuestInviteFrame()
  local questFrame = CreateFrame("Frame", nil, UIParent)
  --questFrame:SetTopLevel(true)
  questFrame:SetMovable(true)
  questFrame:EnableMouse(true)
  questFrame:Hide()
  questFrame:SetSize(384, 512)
  questFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, -104)
  questFrame:SetHitRectInsets(0, 30, 0, 70)
  -- questFrame:SetScript("OnLoad", function() end)
  -- questFrame:SetScript("OnEvent", function() end)
  questFrame:SetScript("OnShow", qf_OnShow)
  questFrame:SetScript("OnHide", qf_OnHide)

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

  local questFrameDeclineButton = CreateFrame("Button", nil, questFrameDetailPanel, "UIPanelButtonTemplate")
  questFrameDeclineButton:SetText("Decline")
  questFrameDeclineButton:SetSize(78, 22)
  questFrameDeclineButton:SetPoint("BOTTOMRIGHT", questFrame, "BOTTOMRIGHT", -39, 72)
  questFrameDeclineButton:SetScript("OnClick", declineButton_OnClick)

  local questFrameAcceptButton = CreateFrame("Button", nil, questFrameDetailPanel, "UIPanelButtonTemplate")
  questFrameAcceptButton:SetText("Accept")
  questFrameAcceptButton:SetSize(77, 22)
  questFrameAcceptButton:SetPoint("BOTTOMLEFT", questFrame, "BOTTOMLEFT", 23, 72)
  questFrameAcceptButton:SetScript("OnClick", acceptButton_OnClick)

  local questDetailScrollFrame = CreateFrame("ScrollFrame", nil, questFrameDetailPanel, "QuestScrollFrameTemplate")
  -- questDetailScrollFrame:SetAllPoints(true)
  local questDetailScrollChildFrame = CreateFrame("Frame", nil, questDetailScrollFrame)
  questDetailScrollChildFrame:SetSize(300, 334)
  questDetailScrollChildFrame:SetPoint("TOPLEFT", questFrameDetailPanel, "TOPLEFT")
  questDetailScrollFrame:SetScrollChild(questDetailScrollChildFrame)

  local questInfoFrame = CreateFrame("Frame", nil, questDetailScrollChildFrame)
  questInfoFrame:SetSize(300, 100)
  questInfoFrame:SetAllPoints(true)

  local article = addon.CustomWidgets:CreateWidget("ArticleText", questInfoFrame)
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

  questFrame.SetTitle = qf_SetTitle
  questFrame.SetContent = qf_SetContent

  return questFrame
end

function addon:ShowQuestInviteFrame(flag, quest)
  if flag == nil then flag = true end
  if flag then
    if not questInviteFrame then
      questInviteFrame = buildQuestInviteFrame()
    end
    if quest then
      questInviteFrame:SetTitle("[PMQ] Quest Invite")
      questInviteFrame:SetContent(quest)
      -- questInviteFrame.scrollFrame:SetVerticalScroll(0)
      currentQuest = quest
      questInviteFrame:Show()
    end
  else
    if questInviteFrame then
      currentQuest = nil
      questInviteFrame:Hide()
    end
  end
end

addon:onload(function()
  -- This expects a fully compiled and built quest
  addon.AppEvents:Subscribe("QuestInvite", function(quest)
    addon:ShowQuestInviteFrame(true, quest)
  end)
end)