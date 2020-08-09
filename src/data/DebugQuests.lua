local _, addon = ...

addon.DebugQuests = addon:NewRepository("DebugQuest", "debugQuestId")
addon.DebugQuests:SetTableSource(addon.DebugQuestDB)
addon.DebugQuests:EnableDirectRead(true)

function addon.DebugQuests:CompileDebugQuest(debugQuestId)
  if not debugQuestId then
    return false, "debugQuestId is required"
  end
  local debugQuest = self:FindByID(debugQuestId)
  if not debugQuest then
    return false, "No demo exists with debugQuestId: "..debugQuestId
  end
  return addon.QuestScriptCompiler:TryCompile(debugQuest.script, { questId = debugQuestId, name = debugQuest.name })
end

function addon.DebugQuests:StartDebugQuest(demoId)
  local ok, quest = self:CompileDebugQuest(demoId)
  if not ok then
    addon.Logger:Error("Unable to start debug quest: %s", quest)
    return
  end
  addon:ShowQuestInfoFrame(true, quest)
end