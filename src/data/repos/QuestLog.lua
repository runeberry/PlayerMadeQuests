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
    error("Failed to add quest: status is required")
    return
  end
  if not QuestStatus[status] then
    error("Failed to add quest: "..status.." is not a valid status")
    return
  end
  if not quest.id then
    quest.id = addon:CreateID("quest-%i")
  else
    local existing = self:FindByID(quest.id)
    if existing then
      error("Failed to add quest: "..quest.id.." already exists")
    end
  end

  table.insert(quests, quest)
  quest.status = status
  self:Save()
  addon.AppEvents:Publish("QuestAdded", quest)
end

function addon.QuestLog:SetQuestStatus(id, status)
  local quest = getQuestById(id)
  if not quest then
    error("Failed to set quest status: no quest by id "..id)
  end
  if not status then
    error("Failed to set quest status: status is required for quest "..id)
  end
  if not QuestStatus[status] then
    error("Failed to set quest status: "..status.." is not a valid status")
  end
  if status ~= quest.status then
    quest.status = status
    for _, obj in pairs(quest.objectives) do
      -- Reset all quest progress when status changes, this should only affect Active -> anything else
      obj.progress = 0
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
    local existing = addon.QuestLog:FindByID(quest.id)
    if existing and considerDuplicate[existing.status] then
      addon.MessageEvents:Publish("QuestInviteDuplicate", { distribution = "WHISPER", target = sender }, quest.id, quest.status)
      return
    end
    addon.Logger:Warn(sender, "has invited you to a quest:", quest.name)
    if existing then
      quest = existing
    else
      addon.QuestEngine:Build(quest) -- Quest is received in "compiled" but not "built" form from message
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