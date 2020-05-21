local _, addon = ...
addon:traceFile("QuestDemos.lua")

addon.QuestDemos = addon.Data:NewRepository("DemoQuests")
addon.QuestDemos:SetDataSource("DemoQuests")
addon.QuestDemos:EnableDirectRead(true)
addon.QuestDemos:AddIndex("id", true)

function addon.QuestDemos:FindByID(id)
  return self:FindByIndex("id", id)
end

function addon.QuestDemos:CopyToDrafts(id)
  local demo = self:FindById(id)
  local draft = addon.QuestDrafts:NewDraft(id)
  draft.script = demo.script
  addon.QuestDrafts:UpdateDraft(draft)
  return draft
end