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

addon.QuestDrafts = addon.Data:NewRepository("Draft")
addon.QuestDrafts:SetSaveDataSource("Drafts")
addon.QuestDrafts:EnableWrite(true)
addon.QuestDrafts:EnablePrimaryKeyGeneration(true)

addon.QuestDraftStatus = {
  Draft = "Draft",
  Testing = "Testing",
  Published = "Published",
  Deprecated = "Deprecated",
}
local status = addon.QuestDraftStatus

function addon.QuestDrafts:NewDraft(name)
  local draft = {
    name = name or "",
    version = 1,
    status = status.Draft,
    listing = {},
    parameters = { name = name or "" },
    script = ""
  }

  return draft
end
