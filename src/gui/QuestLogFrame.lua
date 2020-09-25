local _, addon = ...
local AceGUI = addon.AceGUI
local QuestLog, QuestStatus = addon.QuestLog, addon.QuestStatus

addon.QuestLogFrame = nil -- Built at end of file

local frameOptions = {
  styleOptions = {
    text = "PMQ Quest Log"
  },
  position = {
    p1 = "RIGHT",
    p2 = "RIGHT",
    x = -100,
    y = 0,
    w = 250,
    h = 300,
    shown = true
  },
}

local visConfig = {
  showQuest = {
    [QuestStatus.Active] = true,
    [QuestStatus.Failed] = true,
    [QuestStatus.Finished] = true,
  },
  showStatus = {
    [QuestStatus.Failed] = "(Failed)",
    [QuestStatus.Finished] = "(Complete)",
  },
  showObjectives = {
    [QuestStatus.Active] = true
  },
  questColor = {
    [QuestStatus.Active] = "yellow",
    [QuestStatus.Failed] = "red",
    [QuestStatus.Finished] = "green",
  }
}

local textRedrawEvents = {
  "QuestAdded",
  "QuestUpdated",
  "QuestDeleted",
  "QuestDataReset",
}

local function SetQuestText(label, quest)
  local text = quest.name
  local statusText = visConfig.showStatus[quest.status]
  if statusText then
    text = text.." "..statusText
  end
  local color = visConfig.questColor[quest.status]
  if color then
    text = addon:Colorize(color, text)
  end
  label:SetText(text)
end

local function SetObjectiveText(label, obj)
  local displayText = string.format("    - %s", addon:GetCheckpointDisplayText(obj, "log"))
  if obj.progress >= obj.goal then
    displayText = addon:Colorize("grey", displayText)
  end
  label:SetText(displayText)
end

local function AddQuest(questList, quest)
  if not visConfig.showQuest[quest.status] then return end

  local qLabel = AceGUI:Create("InteractiveLabel")
  qLabel:SetFullWidth(true)
  qLabel:SetHighlight(136810) -- Interface\\QuestFrame\\UI-QuestTitleHighlight
  qLabel:SetCallback("OnClick", function()
    addon.QuestInfoFrame:ShowQuest(quest)
  end)
  questList:AddChild(qLabel)
  SetQuestText(qLabel, quest)

  if not visConfig.showObjectives[quest.status] then return end

  local objList = AceGUI:Create("SimpleGroup")
  questList:AddChild(objList)

  for _, obj in pairs(quest.objectives) do
    local oLabel = AceGUI:Create("InteractiveLabel")
    oLabel:SetFullWidth(true)
    objList:AddChild(oLabel)
    SetObjectiveText(oLabel, obj)
  end
end

local function SetQuestLogText(questList, quests)
  questList:ReleaseChildren()
  for _, quest in pairs(quests) do
    AddQuest(questList, quest)
  end
end

local methods = {
  ["Refresh"] = function(self)
    local quests = QuestLog:FindAll()
    table.sort(quests, function(a,b) return a.questId < b.questId end)
    SetQuestLogText(self._questList, quests)
  end,
}

local function buildQuestLogFrame()
  local frame = addon.CustomWidgets:CreateWidget("ToolWindowPopout", "QuestLogFrame", frameOptions)

  local content = frame:GetContentFrame()

  local scrollGroup = AceGUI:Create("SimpleGroup")
  scrollGroup:SetFullWidth(true)
  scrollGroup:SetFullHeight(true)
  scrollGroup:SetLayout("Fill")

  scrollGroup.frame:SetParent(content)
  scrollGroup.frame:SetAllPoints(true)

  local scroller = AceGUI:Create("ScrollFrame")
  scroller:SetLayout("Flow")
  scrollGroup:AddChild(scroller)

  local buttonGroup = AceGUI:Create("SimpleGroup")
  buttonGroup:SetFullWidth(true)
  scroller:AddChild(buttonGroup)

  local moreButton = AceGUI:Create("Button")
  moreButton:SetText("View Log")
  moreButton:SetWidth(100)
  moreButton:SetCallback("OnClick", function()
    addon.MainMenu:NavToMenuScreen("QuestLogMenu")
  end)
  buttonGroup:AddChild(moreButton)

  local questList = AceGUI:Create("SimpleGroup")
  questList:SetFullWidth(true)
  scroller:AddChild(questList)
  frame._questList = questList

  for fname, fn in pairs(methods) do
    frame[fname] = fn
  end

  frame._subscriptions = {}
  local refresher = function() frame:Refresh() end
  for _, event in ipairs(textRedrawEvents) do
    frame._subscriptions[event] = addon.AppEvents:Subscribe(event, refresher)
  end

  return frame
end

addon:OnGuiStart(function()
  addon.QuestLogFrame = buildQuestLogFrame()
  addon.QuestLogFrame:Refresh()

  local function show()
    addon.QuestLogFrame:Show()
  end

  addon.AppEvents:Subscribe("QuestStarted", show)
end)