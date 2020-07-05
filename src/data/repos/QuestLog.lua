local _, addon = ...
local QuestStatus = addon.QuestStatus
local logger = addon.Logger

addon.QuestLog = {}

local quests = {}

local function resetQuestProgress(quest)
  for _, obj in pairs(quest.objectives) do
    obj.progress = 0
  end
end

local function getQuestById(questId)
  local quest, index
  for i, q in ipairs(quests) do
    if q.questId == questId then
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
    error("Failed to add quest: status is required")
  end
  if not QuestStatus[status] then
    error("Failed to add quest: "..status.." is not a valid status")
  end
  if not quest.questId then
    error("Failed to add quest: questId is required")
  end
  if self:FindByID(quest.questId) then
    error("Failed to add quest: "..quest.questId.." already exists")
  end

  table.insert(quests, quest)
  quest.status = status
  addon.QuestEngine:Validate(quest)
  self:Save()
  addon.AppEvents:Publish("QuestAdded", quest)
end

function addon.QuestLog:SetQuestStatus(questId, status)
  local quest = getQuestById(questId)
  if not quest then
    error("Failed to set quest status: no quest by id "..questId)
  end
  if not status then
    error("Failed to set quest status: status is required for quest "..questId)
  end
  if not QuestStatus[status] then
    error("Failed to set quest status: "..status.." is not a valid status")
  end
  if status ~= quest.status then
    quest.status = status
    if status == QuestStatus.Active then
      resetQuestProgress(quest)
    end
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

local considerDuplicate = {
  [QuestStatus.Active] = "is already on that quest.",
  [QuestStatus.Completed] = "has already completed that quest.",
  [QuestStatus.Archived] = "has archived that quest.",
}

addon:onload(function()
  addon.MessageEvents:Subscribe("QuestInvite", function(distribution, sender, quest)
    local existing = addon.QuestLog:FindByID(quest.questId)
    if existing and considerDuplicate[existing.status] then
      addon.MessageEvents:Publish("QuestInviteDuplicate", { distribution = "WHISPER", target = sender }, quest.questId, quest.status)
      return
    end
    addon.Logger:Warn(sender, "has invited you to a quest:", quest.name)
    if existing then
      quest = existing
    else
      addon.QuestLog:AddQuest(quest, addon.QuestStatus.Invited)
    end
    addon.AppEvents:Publish("QuestInvite", quest, sender)
  end)

  addon.MessageEvents:Subscribe("QuestInviteAccepted", function(distribution, sender, questId)
    addon.Logger:Warn(sender, "accepted your quest.")
  end)
  addon.MessageEvents:Subscribe("QuestInviteDeclined", function(distribution, sender, questId)
    addon.Logger:Warn(sender, "declined your quest.")
  end)
  addon.MessageEvents:Subscribe("QuestInviteDuplicate", function(distribution, sender, questId, status)
    local reason = considerDuplicate[status] or "has already received that quest."
    addon.Logger:Warn(sender, reason)
  end)
  addon.MessageEvents:Subscribe("QuestInviteRequirements", function(distribution, sender, questId)
    addon.Logger:Warn(sender, "does not meet the requirements for that quest.")
  end)
end)