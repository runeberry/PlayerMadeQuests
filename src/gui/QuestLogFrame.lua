local _, addon = ...

local AceGUI = addon.AceGUI
local QuestLog, QuestStatus, localizer = addon.QuestLog, addon.QuestStatus, addon.QuestScriptLocalizer

local frames = {}
local subscriptions = {}

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
  "QuestLogBuilt",
  "QuestAdded",
  "QuestUpdated",
  "QuestDeleted",
  "QuestDataReset",
}

local defaultWindowPos = {
  p1 = "RIGHT",
  p2 = "RIGHT",
  x = -100,
  y = 0,
  w = 250,
  h = 300
}

local function SavePosition()
  local widget = frames["main"]
  if not widget then return end
  addon:SaveWindowPosition(widget.frame, "QuestLogPosition", defaultWindowPos)
end

local function LoadPosition()
  local widget = frames["main"]
  if not widget then return end
  addon:LoadWindowPosition(widget.frame, "QuestLogPosition", defaultWindowPos)
end

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
  local displayText = string.format("    - %s", localizer:GetDisplayText(obj, "log"))
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
    addon:ShowQuestInfoFrame(true, quest)
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

local function refreshQuestText()
  local quests = QuestLog:FindAll()
  table.sort(quests, function(a,b) return a.questId < b.questId end)
  SetQuestLogText(frames["questList"], quests)
end

local function OnOpen()
  addon.PlayerSettings.IsQuestLogShown = true
  LoadPosition()
  refreshQuestText()
end

local function OnClose(widget)
  addon:catch(SavePosition)
  addon.PlayerSettings.IsQuestLogShown = false
  frames = {}
  for event, key in pairs(subscriptions) do

    addon.AppEvents:Unsubscribe(event, key)
  end
  subscriptions = {}
  AceGUI:Release(widget)
end

local function BuildQuestLogFrame()
  local container = AceGUI:Create("Window")
  container:SetTitle("PMQ Quest Log")
  container:SetCallback("OnClose", OnClose)
  container:SetLayout("Flow")
  container.frame:SetFrameStrata("HIGH") -- default Ace frame strata is too high
  container.frame:SetScript("OnLeave", SavePosition)
  frames["main"] = container

  local scrollGroup = AceGUI:Create("SimpleGroup")
  scrollGroup:SetFullWidth(true)
  scrollGroup:SetFullHeight(true)
  scrollGroup:SetLayout("Fill")
  container:AddChild(scrollGroup)

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
    addon.MainMenu:NavToMenuScreen("questlog")
  end)
  buttonGroup:AddChild(moreButton)

  local questList = AceGUI:Create("SimpleGroup")
  questList:SetFullWidth(true)
  scroller:AddChild(questList)
  frames["questList"] = questList

  for _, event in ipairs(textRedrawEvents) do
    subscriptions[event] = addon.AppEvents:Subscribe(event, refreshQuestText)
  end

  OnOpen()
end

function addon:ShowQuestLog(show)
  local mainframe = frames["main"]
  if show == true then
    if mainframe == nil then
      BuildQuestLogFrame()
    end
  elseif mainframe ~= nil then
    -- todo: this might throw an error from AceGUI
    -- just going to suppress it until I can refactor this window
    pcall(OnClose, mainframe)
  end
end

addon.AppEvents:Subscribe("QuestLogBuilt", function()
  if addon.PlayerSettings.IsQuestLogShown or addon.PlayerSettings.IsQuestLogShown == nil then
    addon:ShowQuestLog(true)
  end
end)