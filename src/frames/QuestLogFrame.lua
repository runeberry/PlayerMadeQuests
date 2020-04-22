local _, addon = ...
local AceGUI = addon.AceGUI
local qlog = addon.qlog

local function BuildQuestFrame(quest)

end

local function OnClose(widget)
  PlayerMadeQuestsCache.ShowQuestLog = nil
  AceGUI:Release(widget)
end

function addon:showQuestLog()
  local frame = AceGUI:Create("Frame")
  frame:SetTitle("PlayerMadeQuests")
  frame:SetCallback("OnClose", OnClose)
  frame:SetLayout("Flow")

  local heading = AceGUI:Create("Heading")
  heading:SetText("Quest Log")
  frame:AddChild(heading)

  for _, quest in pairs(qlog.list) do
    local label = AceGUI:Create("Label")
    label:SetText(quest.name)
    frame:AddChild(label)
  end

  _G["PMQ_QuestLogFrame"] = frame.frame
  table.insert(UISpecialFrames, "PMQ_QuestLogFrame")
end
