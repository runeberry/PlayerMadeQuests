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

function addon.QuestDrafts:NewDraft(name)
  local draft = {
    id = addon:CreateID("draft-%i"),
    name = name,
    version = 1,
    status = status.Draft,
    listing = {},
    quest = {},
    script = ""
  }

  drafts[draft.id] = draft

  addon.AppEvents:Publish("DraftCreated", draft)
  return draft
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
