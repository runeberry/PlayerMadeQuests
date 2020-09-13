local _, addon = ...

--[[
  QuestCatalog entity structure:
  {
    questId: "string",  -- The questId copied from the compiled quest object
    quest: {},          -- The compiled quest object
    status: "string",   -- QuestCatalogStatus
    from: {
      source: "string", -- Where the quest came from (QuestCatalogSource)
      id: "string",     -- Unique id of this quest's source (e.g. demoId if source == demo)
      name: "string",   -- The name of the player this quest came from (if applicable)
      realm: "string",  -- The realm of the player this quest came from (if applicable)
    },
  }
--]]

addon.QuestCatalog = addon:NewRepository("CatalogItem", "questId")
addon.QuestCatalog:SetSaveDataSource("QuestCatalog")
addon.QuestCatalog:EnableWrite(true)
addon.QuestCatalog:EnableCompression(true)
addon.QuestCatalog:EnableTimestamps(true)
addon.QuestCatalog:AddIndex("status")

local QuestCatalogStatus = {
  Available = "Available",
  Invited = "Invited",
  Declined = "Declined",
  Accepted = "Accepted",
}
addon.QuestCatalogStatus = QuestCatalogStatus

local QuestCatalogSource = {
  Demo = "Demo",
  Draft = "Draft",
  Shared = "Shared",
}
addon.QuestCatalogSource = QuestCatalogSource

function addon.QuestCatalog:NewCatalogItem(quest)
  assert(quest and quest.questId, "NewCatalogItem failed: a quest must be provided")

  local item = {
    questId = quest.questId,
    quest = addon:CopyTable(quest),
    status = QuestCatalogStatus.Available,
    from = {},
  }

  return item
end

function addon.QuestCatalog:SaveWithStatus(catalogItemOrId, status)
  assert(type(catalogItemOrId) == "table" or type(catalogItemOrId) == "string", "Failed to SaveWithStatus: catalog item or questId are required")
  assert(status ~= nil, "Failed to SaveWithStatus: status is required")
  assert(addon.QuestCatalogStatus[status], "Failed to SaveWithStatus: "..status.." is not a valid status")

  local catalogItem
  if type(catalogItemOrId) == "table" then
    catalogItem = catalogItemOrId
  else
    catalogItem = self:FindByID(catalogItemOrId)
    assert(catalogItem, "Failed to SaveWithStatus: no catalog item exists with id "..catalogItemOrId)
  end

  catalogItem.status = status
  self:Save(catalogItem)
end

function addon.QuestCatalog:StartFromCatalog(questId)
  local catalogItem = self:FindByID(questId)
  if not catalogItem then
    addon.Logger:Error("Failed to StartFromCatalog: no item with id %s", questId)
    return
  end
  addon:ShowQuestInfoFrame(true, catalogItem.quest)
end