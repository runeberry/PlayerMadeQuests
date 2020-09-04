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
  local metadata = { authorName = "PMQ", authorRealm = "", isDemo = true }
  return addon.QuestScriptCompiler:TryCompile(demo.script, { questId = demoId, metadata = metadata })
end

function addon.QuestDemos:CopyToDrafts(demoId, name)
  assert(type(demoId) == "string", "Failed to CopyToDrafts: demoId is required")

  local demo = self:FindByID(demoId)
  local draft = addon.QuestDrafts:NewDraft()

  draft.draftName = name or demo.demoName
  draft.script = demo.script
  draft.parameters = {
    demoId = demo.demoId, -- Each draft created from a demo copy will remember which demo it came from
  }

  addon.QuestDrafts:Save(draft)
  return draft
end

function addon.QuestDemos:StartDemo(demoId)
  local ok, quest = self:CompileDemo(demoId)
  if not ok then
    addon.Logger:Error("Unable to start demo quest: %s", quest)
    return
  end
  addon:ShowQuestInfoFrame(true, quest)
end