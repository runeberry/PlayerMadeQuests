local _, addon = ...
local GetUnitName = addon.G.GetUnitName

addon.QuestLog = addon.Data:NewRepository("Quest", "questId")
addon.QuestLog:SetSaveDataSource("QuestLog")
addon.QuestLog:EnableWrite(true)
addon.QuestLog:EnableCompression(true)
addon.QuestLog:EnableTimestamps(true)

function addon.QuestLog:SaveWithStatus(questOrId, status)
  assert(type(questOrId) == "table" or type(questOrId) == "string", "Failed to SaveWithStatus: quest or questId are required")
  assert(status ~= nil, "Failed to SaveWithStatus: status is required")

  local quest
  if type(questOrId) == "table" then
    quest = questOrId
  else
    quest = self:FindByID(questOrId)
    assert(quest, "Failed to SaveWithStatus: no quest exists with id "..questOrId)
  end

  assert(addon:IsValidQuestStatusChange(quest.status, status))
  quest.status = status
  self:Save(quest)
end

-- todo: (#48) add a DeleteAll/BulkDelete method to Repository
-- https://github.com/dolphinspired/PlayerMadeQuests/issues/48
function addon.QuestLog:Clear()
  local quests = self:FindAll()
  for _, quest in ipairs(quests) do
    self:Delete(quest)
  end
  addon.AppEvents:Publish("QuestLogReset")
  addon.Logger:Info("Quest Log reset")
end

function addon.QuestLog:Validate(quest)
  addon:ValidateQuestStatusChange(quest)
end

function addon.QuestLog:ShareQuest(questId)
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
  addon.Logger:Info("Sharing quest -", catalogItem.quest.name)
end