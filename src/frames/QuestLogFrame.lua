local _, addon = ...
local AceGUI = addon.AceGUI
local qlog = addon.qlog

local qlogFrame = nil

local function SavePosition(widget)
  local p1, _, p2, x, y = widget:GetPoint()
  local w, h = widget.frame:GetSize()
  PlayerMadeQuestsCache.QuestLogPosition = strjoin(",", p1, p2, x, y, w, h)
end

local function LoadPosition(widget)
  if PlayerMadeQuestsCache.QuestLogPosition then
    local p1, p2, x, y, w, h = strsplit(",", PlayerMadeQuestsCache.QuestLogPosition)
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
  PlayerMadeQuestsCache.IsQuestLogShown = true
  qlogFrame = widget
  LoadPosition(widget)
end

local function OnClose(widget)
  addon:catch(SavePosition, widget)
  PlayerMadeQuestsCache.IsQuestLogShown = nil
  qlogFrame = nil
  AceGUI:Release(widget)
end

local function BuildQuestLogFrame()
  local container = AceGUI:Create("Window")
  container:SetTitle("PMQ Quest Log")
  container:SetCallback("OnClose", OnClose)
  container:SetLayout("Flow")

  local questHeader = AceGUI:Create("Heading")
  local numQuests = addon:tlen(qlog.list)
  questHeader:SetText("You have "..numQuests.." "..addon:pluralize(numQuests, "quest").." in your log.")
  questHeader:SetFullWidth(true)
  container:AddChild(questHeader)

  local scrollGroup = AceGUI:Create("SimpleGroup")
  scrollGroup:SetFullWidth(true)
  scrollGroup:SetFullHeight(true)
  scrollGroup:SetLayout("Fill")
  container:AddChild(scrollGroup)

  local scroller = AceGUI:Create("ScrollFrame")
  scroller:SetLayout("Flow")
  scrollGroup:AddChild(scroller)

  for _, quest in pairs(qlog.list) do
    local qLabel = AceGUI:Create("InteractiveLabel")
    qLabel:SetFullWidth(true)
    qLabel:SetText(quest.name.." ("..quest.status..")")
    scroller:AddChild(qLabel)
    for _, obj in pairs(quest.objectives) do
      local oLabel = AceGUI:Create("InteractiveLabel")
      oLabel:SetFullWidth(true)
      oLabel:SetText("    "..obj.unitName) -- todo: make good
      scroller:AddChild(oLabel)
    end
  end

  OnOpen(container)
end

function addon:ShowQuestLog(show)
  if show == true then
    if qlogFrame == nil then
      BuildQuestLogFrame()
    end
  elseif qlogFrame ~= nil then
    OnClose(qlogFrame)
  end
end