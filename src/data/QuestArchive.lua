local _, addon = ...
local GetUnitName = addon.G.GetUnitName

--[[
  Archived quest model:
  -- Same as QuestLog, for now
--]]

addon.QuestArchive = addon:NewRepository("Archive", "questId")
addon.QuestArchive:SetSaveDataSource("QuestArchive")
addon.QuestArchive:EnableWrite(true)
addon.QuestArchive:EnableCompression(true)
addon.QuestArchive:EnableTimestamps(true)

-- Copy/pasted from QuestLog
function addon.QuestArchive:ShareQuest(questId)
  local catalogItem = addon.QuestCatalog:FindByID(questId)
  if not catalogItem then
    -- If the quest is not in the player's catalog for some reason
    -- create a temporary catalog item for the message.
    -- This could happen when trying to share a demo quest.
    local quest = self:FindByID(questId)
    catalogItem = addon.QuestCatalog:NewCatalogItem(quest)
    if quest.demoId then
      catalogItem.metadata.demo = true
      catalogItem.metadata.demoId = quest.demoId
    end
  end

  catalogItem.metadata.sender = GetUnitName("player", true)
  addon.MessageEvents:Publish("QuestInvite", nil, catalogItem)
  addon.Logger:Info("Sharing quest - %s", catalogItem.quest.name)
end