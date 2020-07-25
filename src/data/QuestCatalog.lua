local _, addon = ...
local QuestStatus = addon.QuestStatus
local GetUnitName = addon.G.GetUnitName

--[[
  QuestCatalog entity structure:
  {
    questId: "string",  -- The questId copied from the compiled quest object
    quest: {},          -- The compiled quest object
    status: "string",   -- QuestCatalogStatus
    metadata: {         -- Additional information about this quest (like author, version, create date, etc.)
      author: "string",     -- "name-server" of the player who created this quest
      version: 0,           -- The version of this draft of the quest
      demo: true,           -- True if this quest was generated directly from a demo, nil otherwise
      demoId: "string",     -- The id of the demo this quest or its draft was generated from, if applicable
      draftStatus: "string" -- The status of this version of this draft of the quest
      created: 0,           -- Timestamp indicating when the first version of this draft was originally created
      versionCreated: 0,    -- Timestamp indicating when this version of the quest was created
      published: 0,         -- Timestamp indicating when this version of the quest was moved to "published", if applicable
      sender: "string",     -- "name-server" of the player who invited you to this quest, if applicable
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

function addon.QuestCatalog:NewCatalogItem(quest)
  assert(quest and quest.questId, "NewCatalogItem failed: a quest must be provided")

  local item = {
    questId = quest.questId,
    quest = addon:CopyTable(quest),
    status = QuestCatalogStatus.Available,
    metadata = {},
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

function addon.QuestCatalog:ShareFromCatalog(questId)
  local catalogItem = self:FindByID(questId)
  if not catalogItem then
    addon.Logger:Error("Failed to ShareFromCatalog: no item with id %s", questId)
    return
  end

  catalogItem.metadata.sender = GetUnitName("player", true)
  addon.MessageEvents:Publish("QuestInvite", nil, catalogItem)
  addon.Logger:Info("Sharing quest - %s", catalogItem.quest.name)
end

function addon.QuestCatalog:StartFromCatalog(questId)
  local catalogItem = self:FindByID(questId)
  if not catalogItem then
    addon.Logger:Error("Failed to StartFromCatalog: no item with id %s", questId)
    return
  end
  addon:ShowQuestInfoFrame(true, catalogItem.quest)
end

local considerDuplicate = {
  [QuestCatalogStatus.Accepted] = true,
}

addon:onload(function()
  addon.MessageEvents:Subscribe("QuestInvite", function(distribution, sender, catalogItem)
    -- Check the player's Catalog to see if they're already aware of this quest
    local existingCatalogItem = addon.QuestCatalog:FindByID(catalogItem.questId)
    if existingCatalogItem and considerDuplicate[catalogItem.status] then
      addon.MessageEvents:Publish("QuestInviteDuplicate", { distribution = "WHISPER", target = sender }, catalogItem.questId, catalogItem.status)
      return
    end

    -- Check the player's QuestLog to see if they're already doing (or have done) have this quest
    local quest = addon.QuestLog:FindByID(catalogItem.questId)
    if quest then
      -- Consider this a duplicate, but add the quest to their catalog as "Invited" anyway
      addon.QuestCatalog:SaveWithStatus(catalogItem, QuestCatalogStatus.Invited)
      addon.MessageEvents:Publish("QuestInviteDuplicate", { distribution = "WHISPER", target = sender }, quest.questId, quest.status)
      return
    end

    addon.QuestCatalog:SaveWithStatus(catalogItem, QuestCatalogStatus.Invited)
    addon.Logger:Warn("%s has invited you to a quest: %s", sender, catalogItem.quest.name)
    addon:ShowQuestInfoFrame(true, catalogItem.quest, sender)
  end)

  addon.MessageEvents:Subscribe("QuestInviteAccepted", function(distribution, sender, questId)
    addon.Logger:Warn("%s accepted your quest.", sender)
  end)
  addon.MessageEvents:Subscribe("QuestInviteDeclined", function(distribution, sender, questId)
    addon.Logger:Warn("%s declined your quest.", sender)
  end)
  addon.MessageEvents:Subscribe("QuestInviteDuplicate", function(distribution, sender, questId, status)
    addon.Logger:Warn("%s already has that quest.", sender)
  end)
  addon.MessageEvents:Subscribe("QuestInviteRequirements", function(distribution, sender, questId)
    addon.Logger:Warn("%s does not meet the requirements for that quest.", sender)
  end)
end)