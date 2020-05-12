local _, addon = ...
addon:traceFile("QuestDemos.lua")

--[[
  Demo model:
  {
    id: "string",
    script: "string"
  }
--]]

local demos = {}

addon.QuestDemos = {}

addon:onload(function()
  for _, demo in pairs(addon.DemoQuestDB) do
    demos[demo.id] = demo
  end
end)

function addon.QuestDemos:GetDemos()
  return addon:CopyTable(demos)
end

function addon.QuestDemos:GetDemoByID(id)
  return addon:CopyTable(demos[id])
end

function addon.QuestDemos:CopyToDrafts(id)
  local demo = demos[id]
  local draft = addon.QuestDrafts:NewDraft(id)
  draft.script = demo.script
  addon.QuestDrafts:UpdateDraft(draft)
  return draft
end