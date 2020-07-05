local _, addon = ...
addon:traceFile("QuestDemos.lua")

addon.QuestDemos = addon.Data:NewRepository("DemoQuest")
addon.QuestDemos:SetTableSource(addon.DemoQuestDB)
addon.QuestDemos:EnableDirectRead(true)

function addon.QuestDemos:CopyToDrafts(id)
  local demo = self:FindByID(id)
  local draft = addon.QuestDrafts:NewDraft(id)
  draft.parameters = addon:CopyTable(demo.parameters)
  draft.script = demo.script
  addon.QuestDrafts:Save(draft)
  return draft
end

function addon.QuestDemos:CompileDemo(id)
  if not id then
    return false, "Demo id is required"
  end
  local demo = self:FindByID(id)
  if not demo then
    return false, "No demo exists with id: "..id
  end
  return addon.QuestScriptCompiler:TryCompile(demo.script, demo.parameters)
end