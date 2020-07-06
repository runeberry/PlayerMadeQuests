local _, addon = ...
local QuestStatus = addon.QuestStatus
local logger = addon.Logger:NewLogger("QuestLog", addon.LogLevel.info)

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
  logger:Info("Quest Log reset")
end

function addon.QuestLog:Validate(quest)
  addon:ValidateQuestStatusChange(quest)
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