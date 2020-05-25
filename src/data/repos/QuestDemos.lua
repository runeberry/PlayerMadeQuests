local _, addon = ...
addon:traceFile("QuestDemos.lua")

addon.QuestDemos = addon.Data:NewRepository("DemoQuest")
addon.QuestDemos:SetTableSource(addon.DemoQuestDB)
addon.QuestDemos:EnableDirectRead(true)

function addon.QuestDemos:CopyToDrafts(id)
  local demo = self:FindByID(id)
  local draft = addon.QuestDrafts:NewDraft(id)
  draft.script = demo.script
  addon.QuestDrafts:Save(draft)
  return draft
end