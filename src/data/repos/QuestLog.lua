local _, addon = ...
local QuestStatus = addon.QuestStatus
local logger = addon.Logger:NewLogger("QuestLog", addon.LogLevel.info)

addon.QuestLog = addon.Data:NewRepository("Quest", "questId")
addon.QuestLog:SetSaveDataSource("QuestLog")
addon.QuestLog:EnableWrite(true)
addon.QuestLog:EnableCompression(true)

local statusTracker = {}

local function updateStatusTracker(quest)
  local oldStatus = statusTracker[quest.questId]
  statusTracker[quest.questId] = quest.status
  return oldStatus ~= quest.status, oldStatus
end

function addon.QuestLog:SaveWithStatus(questOrId, status)
  assert(type(questOrId) == "table" or type(questOrId) == "string", "Failed to SaveWithStatus: quest or questId are required")
  assert(status ~= nil, "Failed to SaveWithStatus: status is required")
  assert(QuestStatus[status], status.." is not a valid status")

  local quest
  if type(questOrId) == "table" then
    quest = questOrId
  else
    quest = self:FindByID(questOrId)
    assert(quest, "Failed to SaveWithStatus: no quest exists with id "..questOrId)
  end

  quest.status = status
  self:Save(quest)
end

-- todo: add a DeleteAll/BulkDelete method to Repository
function addon.QuestLog:Clear()
  local quests = self:FindAll()
  for _, quest in ipairs(quests) do
    self:Delete(quest)
  end
  addon.AppEvents:Publish("QuestLogReset")
  logger:Info("Quest Log reset")
end

function addon.QuestLog:Validate(quest)
  assert(quest.status, "status is required")
  assert(QuestStatus[quest.status], quest.status.." is not a valid status")
  local changed, oldStatus = updateStatusTracker(quest)
  if changed then
    if quest.status == QuestStatus.Active then
      -- Reset all quest progress when a quest first moves into active status
      for _, obj in pairs(quest.objectives) do
        obj.progress = 0
      end
      logger:Trace("Resetting quest progress: moved from", oldStatus, "to", quest.status)
    end
    -- todo: this should technically only fire after the save was successful
    addon.AppEvents:Publish("QuestStatusChanged", quest, oldStatus)
  end
end

addon.AppEvents:Subscribe("QuestAdded", function(quest)
  statusTracker[quest.questId] = quest.status
end)
addon.AppEvents:Subscribe("QuestDeleted", function(quest)
  statusTracker[quest.questId] = nil
end)
addon.AppEvents:Subscribe("QuestDataLoaded", function()
  local quests = addon.QuestLog:FindAll()
  for _, q in ipairs(quests) do
    statusTracker[q.questId] = q.status
  end
end)

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
    logger:Warn(sender, "has invited you to a quest:", quest.name)
    if existing then
      quest = existing
    else
      quest.status = QuestStatus.Invited
      addon.QuestLog:Save(quest)
    end
    addon.AppEvents:Publish("QuestInvite", quest, sender)
  end)

  addon.MessageEvents:Subscribe("QuestInviteAccepted", function(distribution, sender, questId)
    logger:Warn(sender, "accepted your quest.")
  end)
  addon.MessageEvents:Subscribe("QuestInviteDeclined", function(distribution, sender, questId)
    logger:Warn(sender, "declined your quest.")
  end)
  addon.MessageEvents:Subscribe("QuestInviteDuplicate", function(distribution, sender, questId, status)
    local reason = considerDuplicate[status] or "has already received that quest."
    logger:Warn(sender, reason)
  end)
  addon.MessageEvents:Subscribe("QuestInviteRequirements", function(distribution, sender, questId)
    logger:Warn(sender, "does not meet the requirements for that quest.")
  end)
end)