local _, addon = ...
addon:traceFile("QuestDrafts.lua")

--[[
  Draft model:
  {
    draftId: "string",
    version: 1,
    status: "string",
    parameters: {}, -- Predefined parameters for the QuestEngine
    script: "string" -- QuestScript that will be applied to the parameters
  }
--]]

addon.QuestDrafts = addon.Data:NewRepository("Draft", "draftId")
addon.QuestDrafts:SetSaveDataSource("Drafts")
addon.QuestDrafts:EnableWrite(true)
addon.QuestDrafts:EnableCompression(true)
addon.QuestDrafts:EnableGlobalSaveData(true)
addon.QuestDrafts:EnableTimestamps(true)

addon.QuestDraftStatus = {
  Draft = "Draft",
  Testing = "Testing",
  Published = "Published",
  Deprecated = "Deprecated",
}
local status = addon.QuestDraftStatus

function addon.QuestDrafts:NewDraft()
  local draft = {
    draftId = addon:CreateID("draft-%i"),
    version = 1,
    status = status.Draft,
    parameters = {},
    script = ""
  }

  return draft
end

function addon.QuestDrafts:CompileDraft(draftId)
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
  if not draft.parameters then
    draft.parameters = {}
  end
  if not draft.parameters.questId then
    -- This will ensure that the quest gets the same id on every recompilation of the draft
    draft.parameters.questId = quest.questId
    self:Save(draft)
  end
  return true, quest
end