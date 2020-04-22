local _, addon = ...
local qlog = addon.qlog
local AceGUI = addon.AceGUI
addon:traceFile("QuestLogFrame.lua")

local frame = AceGUI:Create("Frame")
frame:SetTitle("PlayerMadeQuests")
frame:SetStatusText("Getcha quests here")
frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
frame:SetLayout("Flow")

local editbox = AceGUI:Create("EditBox")
editbox:SetLabel("Insert text:")
editbox:SetWidth(200)
frame:AddChild(editbox)

local button = AceGUI:Create("Button")
button:SetText("Click Me!")
button:SetWidth(200)
frame:AddChild(button)