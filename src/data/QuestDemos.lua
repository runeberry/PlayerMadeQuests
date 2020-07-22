local _, addon = ...

--[[
  Demo model:
    See DemoQuestDB.lua
--]]

addon.QuestDemos = addon:NewRepository("DemoQuest", "demoId")
addon.QuestDemos:SetTableSource(addon.DemoQuestDB)
addon.QuestDemos:EnableDirectRead(true)

function addon.QuestDemos:CompileDemo(demoId)
  if not demoId then
    return false, "demoId is required"
  end
  local demo = self:FindByID(demoId)
  if not demo then
    return false, "No demo exists with demoId: "..demoId
  end
  demo.parameters.questId = demoId
  return addon.QuestScriptCompiler:TryCompile(demo.script, demo.parameters)
end

function addon.QuestDemos:CopyToDrafts(demoId)
  local demo = self:FindByID(demoId)
  local draft = addon.QuestDrafts:NewDraft()
  draft.parameters = addon:CopyTable(demo.parameters)
  draft.parameters.name = demo.name
  draft.parameters.questId = nil -- Each copy of the demo is considered a new quest
  draft.parameters.demoId = demo.demoId -- ..but it will still keep a reference to the demo it was created from
  draft.script = demo.script
  addon.QuestDrafts:Save(draft)
  return draft
end

function addon.QuestDemos:StartDemo(demoId)
  local ok, quest = self:CompileDemo(demoId)
  if not ok then
    addon.Logger:Error("Unable to start demo quest:", quest)
    return
  end
  addon:ShowQuestInfoFrame(true, quest)
end