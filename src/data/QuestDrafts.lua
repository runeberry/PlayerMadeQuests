local _, addon = ...

--[[
  Draft model:
  {
    questId: "string",
    version: 1,
    status: "string",
    parameters: {}, -- Predefined parameters for the QuestEngine
    script: "string" -- QuestScript that will be applied to the parameters
  }
--]]

local QuestDrafts = addon:NewRepository("Draft", "draftId")
QuestDrafts:SetSaveDataSource("Drafts")
QuestDrafts:EnableWrite(true)
QuestDrafts:EnableCompression(true)
QuestDrafts:EnableGlobalSaveData(true)
QuestDrafts:EnableTimestamps(true)
addon.QuestDrafts = QuestDrafts

addon.QuestDraftStatus = {
  Draft = "Draft",
  Testing = "Testing",
  Published = "Published",
  Deprecated = "Deprecated",
}
local status = addon.QuestDraftStatus

function QuestDrafts:NewDraft()
  local draft = {
    draftId = addon:CreateID("draft-%i"),
    version = 1,
    status = status.Draft,
    parameters = {},
    script = ""
  }

  return draft
end

function QuestDrafts:FindByQuestID(questId)
  local drafts = self:FindByQuery(function(d) return d.parameters.questId == questId end)
  if #drafts > 1 then
    addon.Logger:Warn("Ambigious draft match on questId: %s (%i results)", questId, #drafts)
    return
  end
  return drafts[1]
end

function QuestDrafts:TryCompileDraft(draftId)
  if not draftId then
    return false, "draftId is required"
  end
  local draft = self:FindByID(draftId)
  if not draft then
    return false, "No draft exists with draftId: "..draftId
  end
  local ok, quest = addon.QuestScriptCompiler:TryCompile(draft.script, draft.parameters)
  if not ok then
    return ok, quest
  end
  if not draft.parameters.questId then
    -- This will ensure that the quest gets the same id on every recompilation of the draft
    draft.parameters.questId = quest.questId
    self:Save(draft)
  end
  return true, quest
end

function QuestDrafts:StartDraft(draftId)
  local ok, quest = self:TryCompileDraft(draftId)
  if not ok then
    addon.Logger:Warn("Failed to start draft: %s", quest)
    return
  end
  addon:ShowQuestInfoFrame(true, quest)
end