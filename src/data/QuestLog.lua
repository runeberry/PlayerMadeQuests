local _, addon = ...
local GetUnitName = addon.G.GetUnitName

--[[
  Quest model:
  {
    questId: "string",        -- Required, globally unique between all users (can be safely shared)
    addonVersion: 0,          -- Required, version of PMQ that the quest was compiled with
    name: "string",           -- Required
    source: "string",         -- Indicates where the quest was before the QuestLog (catalog, demo, draft)
    description: "string",    -- Flavor text shown on quest start
    completion: "string",     -- Flavor text shown when quest is Completed
    status = "string",        -- see QuestStatus.lua
    objectives: {             -- array of trackable quest objectives
      {
        name = "string",          -- name of the QuestEvent which will trigger evaluation of this objective
        displayText = {           -- variations of text that will be shown
          log = "string",             -- shown in the quest log window (light details)
          progress = "string",        -- shown when an objective is progressed (light details)
          quest = "string",           -- shown in the QuestInfoFrame (most details)
          full = "string",            -- shown for spoilers (full details)
        },
        goal = 1,                 -- number of times these conditions must be met to complete this objective (min. 1)
        conditions = {            -- map of conditions <> expected value(s) for that condition (examples shown)
          emote = { "val1": true },
          target = { "val2": true, "val3": true },
        }
      }
    }
  }
--]]

addon.QuestLog = addon:NewRepository("Quest", "questId")
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
  addon.Logger:Warn("Sharing quest %s...", catalogItem.quest.name)
end