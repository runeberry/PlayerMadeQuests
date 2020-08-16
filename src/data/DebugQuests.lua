local _, addon = ...

addon.DebugQuests = addon:NewRepository("DebugQuest", "questId")
addon.DebugQuests:SetTableSource(addon.DebugQuestDB)
addon.DebugQuests:EnableDirectRead(true)

function addon.DebugQuests:CompileDebugQuest(questId)
  if not questId then
    return false, "questId is required"
  end
  local debugQuest = self:FindByID(questId)
  if not debugQuest then
    return false, "No demo exists with questId: "..questId
  end
  return addon.QuestScriptCompiler:TryCompile(debugQuest.script, debugQuest.parameters)
end

function addon.DebugQuests:StartDebugQuest(questId)
  local ok, quest = self:CompileDebugQuest(questId)
  if not ok then
    addon.Logger:Error("Unable to start debug quest: %s", quest)
    return
  end
  addon:ShowQuestInfoFrame(true, quest)
end