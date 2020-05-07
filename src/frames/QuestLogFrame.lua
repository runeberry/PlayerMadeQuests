local _, addon = ...
addon:traceFile("QuestLogFrame.lua")

local AceGUI = addon.AceGUI
local strjoin = addon.G.strjoin
local strsplit = addon.G.strsplit
local UIParent = addon.G.UIParent

local frames = {}
local subscriptions = {}
local savedSettings
local qlog = {}

local function SavePosition(widget)
  local p1, _, p2, x, y = widget:GetPoint()
  local w, h = widget.frame:GetSize()
  savedSettings.QuestLogPosition = strjoin(",", p1, p2, x, y, w, h)
end

local function LoadPosition(widget)
  if savedSettings.QuestLogPosition then
    local p1, p2, x, y, w, h = strsplit(",", savedSettings.QuestLogPosition)
    widget:SetPoint(p1, UIParent, p2, x, y)
    widget:SetWidth(w)
    widget:SetHeight(h)
  else
    widget:SetPoint("RIGHT", UIParent, "RIGHT", -100, 0)
    widget:SetWidth(250)
    widget:SetHeight(300)
  end
end

local function OnOpen(widget)
  savedSettings.IsQuestLogShown = true
  LoadPosition(widget)
end

local function OnClose(widget)
  addon:catch(SavePosition, widget)
  savedSettings.IsQuestLogShown = nil
  frames = {}
  for event, key in pairs(subscriptions) do

    addon.AppEvents:Unsubscribe(event, key)
  end
  subscriptions = {}
  AceGUI:Release(widget)
end

local function SetQuestLogHeadingText(heading, qlog)
  local numQuests = addon:tlen(qlog)
  heading:SetText("You have "..numQuests.." "..addon:pluralize(numQuests, "quest").." in your log.")
end

local function SetQuestText(label, quest)
  local text = quest.name
  if quest.status == addon.QuestStatus.Completed then
    text = text.." (Complete)"
  end
  label:SetText(text)
end

local function SetObjectiveText(label, obj)
  label:SetText("    "..obj.name)
end

local function AddQuest(questList, quest)
  local qLabel = AceGUI:Create("InteractiveLabel")
  qLabel:SetFullWidth(true)
  questList:AddChild(qLabel)
  SetQuestText(qLabel, quest)
  frames[quest.id] = qLabel

  local objList = AceGUI:Create("SimpleGroup")
  questList:AddChild(objList)

  for _, obj in pairs(quest.objectives) do
    local oLabel = AceGUI:Create("InteractiveLabel")
    oLabel:SetFullWidth(true)
    objList:AddChild(oLabel)
    SetObjectiveText(oLabel, obj)
    frames[obj.id] = oLabel
  end
end

local function SetQuestLogText(questList, qlog)
  questList:ReleaseChildren()
  for _, quest in pairs(qlog) do
    AddQuest(questList, quest)
  end
end

local function BuildQuestLogFrame()
  local container = AceGUI:Create("Window")
  container:SetTitle("PMQ Quest Log")
  container:SetCallback("OnClose", OnClose)
  container:SetLayout("Flow")
  frames["main"] = container

  local questHeading = AceGUI:Create("Heading")
  questHeading:SetFullWidth(true)
  container:AddChild(questHeading)
  frames["heading"] = questHeading

  local scrollGroup = AceGUI:Create("SimpleGroup")
  scrollGroup:SetFullWidth(true)
  scrollGroup:SetFullHeight(true)
  scrollGroup:SetLayout("Fill")
  container:AddChild(scrollGroup)

  local scroller = AceGUI:Create("ScrollFrame")
  scroller:SetLayout("Flow")
  scrollGroup:AddChild(scroller)

  local questList = AceGUI:Create("SimpleGroup")
  questList:SetFullWidth(true)
  scroller:AddChild(questList)
  frames["questList"] = questList

  SetQuestLogHeadingText(questHeading, qlog)
  SetQuestLogText(questList, qlog)

  local subKey
  subKey = addon.AppEvents:Subscribe("QuestLogLoaded", function(qlog)
    SetQuestLogHeadingText(frames["heading"], qlog)
    SetQuestLogText(frames["questList"], qlog)
  end)
  subscriptions["QuestLogLoaded"] = subKey

  subKey = addon.AppEvents:Subscribe("QuestAccepted", function(quest)
    SetQuestLogHeadingText(frames["heading"], qlog)
    AddQuest(frames["questList"], quest)
  end)
  subscriptions["QuestAccepted"] = subKey

  subKey = addon.AppEvents:Subscribe("QuestStatusChanged", function(quest)
    SetQuestText(frames[quest.id], quest)
  end)
  subscriptions["QuestStatusChanged"] = subKey

  subKey = addon.AppEvents:Subscribe("ObjectiveUpdated", function(obj)
    SetObjectiveText(frames[obj.id], obj)
  end)
  subscriptions["ObjectiveUpdated"] = subKey

  OnOpen(container)
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

addon:OnSaveDataLoaded(function()
  savedSettings = addon.SaveData:LoadTable("Settings")
end)

addon.AppEvents:Subscribe("QuestLogLoaded", function(quests)
  qlog = quests
end)