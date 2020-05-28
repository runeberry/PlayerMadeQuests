local _, addon = ...
addon:traceFile("QuestDemos.lua")

addon.QuestDemos = addon.Data:NewRepository("DemoQuest")
addon.QuestDemos:SetTableSource(addon.DemoQuestDB)
addon.QuestDemos:EnableDirectRead(true)

function addon.QuestDemos:CopyToDrafts(id)
  local demo = self:FindByID(id)
  local draft = addon.QuestDrafts:NewDraft(id)
  draft.name = demo.name
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
  local ok, parameters = pcall(addon.QuestEngine.Compile, addon.QuestEngine, demo.script, { name = demo.name })
  if not ok then
    return ok, parameters
  end
  local quest
  ok, quest = pcall(addon.QuestEngine.Build, addon.QuestEngine, parameters)
  if not ok then
    return ok, quest
  end
  return true, quest
end