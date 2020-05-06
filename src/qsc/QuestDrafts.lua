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
  addon.QuestDrafts:Load()
end)

function addon.QuestDrafts:Save()
  addon.SaveData:Save("Drafts", drafts)
  addon.AppEvents:Publish("DraftsSaved")
end

function addon.QuestDrafts:Load()
  drafts = addon.SaveData:LoadTable("Drafts")
  addon.AppEvents:Publish("DraftsLoaded")
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

  drafts[draft.id] = draft
  self:Save()

  draft = addon:CopyTable(draft)
  addon.AppEvents:Publish("DraftCreated", draft.id, draft)
  return draft
end

function addon.QuestDrafts:GetDraftByID(id)
  local draft = drafts[id]
  if draft == nil then return nil end
  return addon:CopyTable(draft)
end

function addon.QuestDrafts:UpdateDraft(id, patch)
  if type(id) == "table" then
    -- If id was not specified, then use the id from the patch object
    patch = id
    id = patch.id
  end

  if id == nil then
    addon:warn("Unable to update draft: no id was specified")
    return nil
  end
  if patch == nil then
    addon:warn("Unable to update draft: no patch object was specified")
    return nil
  end

  local draft = drafts[id]
  if draft == nil then
    addon:warn("Unable to update draft: no draft exists with id", id)
    return nil
  end

  local changed = false
  if patch.name and draft.name ~= patch.name then
    draft.name = patch.name
    changed = true
  end
  if patch.version and draft.version ~= patch.version then
    draft.version = patch.version
    changed = true
  end
  if patch.status and draft.status ~= patch.status then
    draft.status = patch.status
    changed = true
  end
  if patch.script and draft.script ~= patch.script then
    draft.script = patch.script
    changed = true
  end

  draft = addon:CopyTable(draft)
  if changed then
    self:Save()
    addon.AppEvents:Publish("DraftUpdated", id, draft)
  end
  return draft
end

function addon.QuestDrafts:DeleteDraft(id)
  local draft = drafts[id]
  if draft == nil then
    return
  end

  drafts[id] = nil
  self:Save()
  addon.AppEvents:Publish("DraftDeleted", id)
end
