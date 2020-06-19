local _, addon = ...
local QuestStatus = addon.QuestStatus
local logger = addon.Logger

addon.QuestLog = {}

local quests = {}

local function getQuestById(id)
  local quest, index
  for i, q in ipairs(quests) do
    if q.id == id then
      quest = q
      index = i
      break
    end
  end
  return quest, index
end

addon:OnSaveDataLoaded(function()
  addon.AppEvents:Subscribe("EngineLoaded", function()
    addon.QuestLog:Load()
  end)
end)

function addon.QuestLog:Save()
  local compressed = addon:CompressTable(quests)
  addon.SaveData:Save("QuestLog", compressed)
end

function addon.QuestLog:Load()
  local compressed = addon.SaveData:LoadString("QuestLog")
  if compressed and compressed ~= "" then
    quests = addon:DecompressTable(compressed)
  end
  addon.AppEvents:Publish("QuestLogLoaded", quests)
end

function addon.QuestLog:FindAll()
  return quests
end

function addon.QuestLog:FindByID(id)
  local quest = getQuestById(id)
  return quest
end

function addon.QuestLog:Clear()
  quests = {}
  self:Save()
  addon.AppEvents:Publish("QuestLogReset")
  logger:Info("Quest Log reset")
end

-- This expects a fully compiled and built quest
function addon.QuestLog:AddQuest(quest, status)
  if not status then
    addon.Logger:Error("Failed to add quest: status is required")
    return
  end
  if not QuestStatus[status] then
    addon.Logger:Error("Failed to add quest:", status, "is not a valid status")
    return
  end
  if quest.id then
    addon.Logger:Warn("Overwriting quest id:", quest.id)
  end
  quest.id = addon:CreateID("quest-%i")
  table.insert(quests, quest)
  quest.status = status
  self:Save()
  addon.AppEvents:Publish("QuestAdded", quest)
end

function addon.QuestLog:SetQuestStatus(id, status)
  local quest = getQuestById(id)
  if not quest then
    addon.Logger:Error("Failed to set quest status: no quest by id", id)
    return
  end
  if not status then
    addon.Logger:Error("Failed to set quest status: status is required for quest", id)
    return
  end
  if not QuestStatus[status] then
    addon.Logger:Error("Failed to set quest status:", status, "is not a valid status")
    return
  end
  if status ~= quest.status then
    quest.status = status
    self:Save()
    addon.AppEvents:Publish("QuestStatusChanged", quest)
  end
end

function addon.QuestLog:DeleteQuest(id)
  local quest, index = getQuestById(id)
  if not quest then
    addon.Logger:Error("Failed to delete quest: no quest by id", id)
    return
  end
  table.remove(quests, index)
  self:Save()
  addon.AppEvents:Publish("QuestDeleted", quest)
end

addon:onload(function()
  addon.MessageEvents:Subscribe("QuestInvite", function(distribution, sender, quest)
    addon.Logger:Info(sender, "has invited you to a quest:", quest.name)
    addon.QuestEngine:Build(quest) -- Quest is received in "compiled" but not "built" form from message
    addon.QuestLog:AddQuest(quest, addon.QuestStatus.Invited)
    addon.AppEvents:Publish("QuestInvite", quest)
  end)
end)