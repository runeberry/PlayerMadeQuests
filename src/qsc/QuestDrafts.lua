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

function addon.QuestDrafts:Save()
  addon.SaveData:Save("Drafts", drafts)
  addon.AppEvents:Publish("DraftsSaved", drafts)
end

function addon.QuestDrafts:Load()
  drafts = addon.SaveData:LoadTable("Drafts")
  addon.AppEvents:Publish("DraftsLoaded", drafts)
end

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

  table.insert(drafts, draft)
  self:Save()
  return draft
end

addon:onload(function()
  addon.QuestDrafts:Load()
end)