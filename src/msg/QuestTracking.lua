local _, addon = ...
local logger = addon.Logger:NewLogger("Tracking")
local MessageEvents, MessageDistribution, MessagePriority = addon.MessageEvents, addon.MessageDistribution, addon.MessagePriority
local QuestStatus = addon.QuestStatus
local IsInGroup, IsInRaid = addon.G.IsInGroup, addon.G.IsInRaid

-- Cache the last known quest status per player to avoid duplicate notifications
local questStatusCache = {}
local playerName

-- Status messages are indexed by the context in which the message should be displayed.
-- This is passed as the "reason" parameter when a status change message is published.
local statusMessages = {
  ["author"] = {
    [QuestStatus.Completed] = "%s has completed your quest: %s"
  },
  ["sharer"] = {
    [QuestStatus.Completed] = "%s has completed a quest you shared: %s"
  },
  ["bulk"] = {
    [QuestStatus.Completed] = "%s has completed a quest: %s"
  },
}

-- The values for these config keys are populated below
local notificationsEnabled = {
  ["author"] = "NOTIFY_COMPLETE_AUTHOR",
  ["sharer"] = "NOTIFY_COMPLETE_SHARER",
  ["bulk"] = "NOTIFY_COMPLETE_BULK",
}

local function notifyStatusChange(sender, questName, questStatus, reason)
  if not notificationsEnabled[reason] then return end
  local text = statusMessages[reason][questStatus]
  if not text then return end -- Nothing to notify for this quest status
  addon.Logger:Info(text, sender, questName)
end

local function publish(quest, distro, target, reason)
  local opts = { distribution = distro, target = target, priority = MessagePriority.Bulk }
  MessageEvents:Publish("QuestStatusChanged", opts, quest.name, quest.status, reason)
end

addon:OnBackendStart(function()
  playerName = addon:GetPlayerName()

  for k, v in pairs(notificationsEnabled) do
    notificationsEnabled[k] = addon.Config:GetValue(v)
  end

  MessageEvents:Subscribe("QuestStatusChanged", function(distribution, sender, questName, questStatus, reason)
    logger:Trace("Quest status update from %s for '%s': %s", sender, questName, questStatus)
    local cacheKey = string.format("%s:%s", sender, questName)
    if questStatusCache[cacheKey] == questStatus then return end -- No duplicate updates for same status

    questStatusCache[cacheKey] = questStatus
    notifyStatusChange(sender, questName, questStatus, reason)
  end)

  -- When a player's quest status changes, notify all concerned parties
  addon.AppEvents:Subscribe("QuestStatusChanged", function(quest)
    if quest.metadata.giverName and quest.metadata.giverName ~= playerName then
      logger:Trace("Notifying SHARER of quest status change")
      publish(quest, MessageDistribution.Whisper, quest.metadata.giverName, "sharer")
    end

    if quest.metadata.authorName and quest.metadata.authorName ~= playerName then
      logger:Trace("Notifying AUTHOR of quest status change")
      publish(quest, MessageDistribution.Whisper, quest.metadata.authorName, "author")
    end

    if IsInRaid() then
      logger:Trace("Notifying RAID of quest status change")
      publish(quest, MessageDistribution.Raid, nil, "bulk")
    elseif IsInGroup() then
      logger:Trace("Notifying PARTY of quest status change")
      publish(quest, MessageDistribution.Party, nil, "bulk")
    end
  end)
end)