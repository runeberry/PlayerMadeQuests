local _, addon = ...
addon:traceFile("QuestDrafts.lua")

--[[
  Draft model:
  {
    id: "string",
    name: "string",
    version: 1,
    status: "string",
    listing: {}, -- Information about this quest in the catalog
    quest: {}, -- Predefined parameters for the QuestEngine
    script: "string" -- QuestScript that will be applied to the above "quest" object
  }
--]]

local drafts = {}

addon.QuestDrafts = {}
addon.QuestDraftStatus = {
  Draft = "Draft",
  Testing = "Testing",
  Published = "Published",
  Deprecated = "Deprecated",
}
local status = addon.QuestDraftStatus

addon:OnSaveDataLoaded(function()
  drafts = addon.SaveData:LoadTable("Drafts")
  addon.AppEvents:Publish("DraftsLoaded", drafts)
end)

-- Does not save the draft to SavedVariables until you call SaveDraft
function addon.QuestDrafts:NewDraft(name)
  local draft = {
    id = addon:CreateID("draft-%i"),
    name = name or "",
    version = 1,
    status = status.Draft,
    listing = {},
    parameters = { name = name or "" },
    script = ""
  }

  return draft
end

function addon.QuestDrafts:SaveDraft(draft)
  if not draft.id then
    addon.Logger:Error("Failed to save draft: id is required")
  end

  local existing = drafts[draft.id]
  if existing then
    if existing ~= draft then
      -- Apply the provided draft as a patch to the existing one
      draft = addon:MergeTable(existing, draft)
      drafts[draft.id] = draft
    end
    -- Otherwise, the draft in the table is already updated, nothing to do
  else
    -- New draft, stick it in the table
    drafts[draft.id] = draft
  end

  addon.SaveData:Save("Drafts", drafts)
  addon.AppEvents:Publish("DraftSaved", draft)
  return draft
end

function addon.QuestDrafts:GetDrafts()
  return drafts
end

function addon.QuestDrafts:GetDraftByID(id)
  return drafts[id]
end

function addon.QuestDrafts:DeleteDraft(id)
  local draft = drafts[id]
  if draft == nil then
    return
  end

  drafts[id] = nil
  addon.AppEvents:Publish("DraftDeleted", draft)
end
