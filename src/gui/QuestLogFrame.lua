local _, addon = ...

local AceGUI = addon.AceGUI
local strjoin, strsplit = addon.G.strjoin, addon.G.strsplit
local UIParent = addon.G.UIParent
local QuestLog, QuestStatus, localizer = addon.QuestLog, addon.QuestStatus, addon.QuestScriptLocalizer

local frames = {}
local subscriptions = {}

local wp = {
  p1 = "RIGHT",
  p2 = "RIGHT",
  x = -100,
  y = 0,
  w = 250,
  h = 300
}

local visConfig = {
  showQuest = {
    [QuestStatus.Active] = true,
    [QuestStatus.Failed] = true,
    [QuestStatus.Completed] = true,
  },
  showStatus = {
    [QuestStatus.Failed] = true,
    [QuestStatus.Completed] = true,
  },
  showObjectives = {
    [QuestStatus.Active] = true
  },
  questColor = {
    [QuestStatus.Active] = "yellow",
    [QuestStatus.Failed] = "red",
    [QuestStatus.Completed] = "green",
  }
}

local textRedrawEvents = {
  "QuestLogBuilt",
  "QuestAdded",
  "QuestUpdated",
  "QuestDeleted",
  "QuestDataReset",
}

-- For some reason GetPoint() returns the wrong position unless you move the window
-- Still trying to figure this one out
local function isInaccuratePoint(p1, p2, x, y)
  return p1 == "CENTER" and p2 == "CENTER" and x == 0 and y == 0
end

local function SavePosition()
  local widget = frames["main"]
  if not widget then return end
  local p1, _, p2, x, y = widget:GetPoint()
  if isInaccuratePoint(p1, p2, x, y) then
    p1 = wp.p1
    p2 = wp.p2
    x = wp.x
    y = wp.y
  end
  local w, h = widget.frame:GetSize()
  addon.PlayerSettings.QuestLogPosition = strjoin(",", p1, p2, x, y, w, h)
end

local function LoadPosition()
  local widget = frames["main"]
  if not widget then return end
  if addon.PlayerSettings.QuestLogPosition then
    local p1, p2, x, y, w, h = strsplit(",", addon.PlayerSettings.QuestLogPosition)
    wp.p1 = p1
    wp.p2 = p2
    wp.x = x
    wp.y = y
    wp.w = w
    wp.h = h
  end

  widget:SetPoint(wp.p1, UIParent, wp.p2, wp.x, wp.y)
  widget:SetWidth(wp.w)
  widget:SetHeight(wp.h)
end

local function SetQuestText(label, quest)
  local text = quest.name
  if visConfig.showStatus[quest.status] then
    text = text.." ("..quest.status..")"
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
    OnClose(mainframe)
  end
end

addon.AppEvents:Subscribe("QuestLogBuilt", function()
  if addon.PlayerSettings.IsQuestLogShown or addon.PlayerSettings.IsQuestLogShown == nil then
    addon:ShowQuestLog(true)
  end
end)