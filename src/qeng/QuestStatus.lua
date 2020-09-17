local _, addon = ...

-- Keep track of the status changes of each quest and react accordingly
local statusTracker = {}

local qs = {
  Active = "Active",
  Failed = "Failed",
  Abandoned = "Abandoned",
  Finished = "Finished",
  Completed = "Completed",
}
addon.QuestStatus = qs

local function valid() return { valid = true } end
local function invalid(reason) return { valid = false, reason = reason } end

-- Based on the table outlined here:
-- https://docs.google.com/spreadsheets/d/1AbWMzTdotk8LcpgInZatYNd64RNvJnHOORzYzcjdwh0/edit?usp=sharing
local validStatusTable = {
  [qs.Active] = {
    [qs.Active] = valid(),
    [qs.Failed] = valid(),
    [qs.Abandoned] = valid(),
    [qs.Finished] = valid(),
    [qs.Completed] = invalid("A quest can only be completed from the Finished status."),
  },
  [qs.Failed] = {
    [qs.Active] = valid(),
    [qs.Failed] = valid(),
    [qs.Abandoned] = valid(),
    [qs.Finished] = invalid("A quest can only be finished from the Active status."),
    [qs.Completed] = invalid("A quest can only be completed from the Finished status."),
  },
  [qs.Abandoned] = {
    [qs.Active] = valid(),
    [qs.Failed] = invalid("A quest can only be failed from the Active status."),
    [qs.Abandoned] = valid(),
    [qs.Finished] = invalid("A quest can only be finished from the Active status."),
    [qs.Completed] = invalid("A quest can only be completed from the Finished status."),
  },
  [qs.Finished] = {
    [qs.Active] = valid(),
    [qs.Failed] = invalid("A quest can only be failed from the Active status."),
    [qs.Abandoned] = valid(),
    [qs.Finished] = valid(),
    [qs.Completed] = valid(),
  },
  [qs.Completed] = {
    [qs.Active] = valid(),
    [qs.Failed] = invalid("A quest can only be failed from the Active status."),
    [qs.Abandoned] = invalid("A completed quest cannot be returned to the Abandoned status."),
    [qs.Finished] = invalid("A completed quest cannot be returned to the Finished status."),
    [qs.Completed] = valid(),
  },
}

function addon:IsValidQuestStatusChange(oldStatus, newStatus)
  if oldStatus == newStatus then
    -- No change
    return true
  end
  if newStatus == nil then
    return false, "Cannot change quest status to nil"
  end
  if not qs[newStatus] then
    return false, string.format("Invalid quest status: %s", newStatus)
  end
  if oldStatus == nil then
    -- Currently no requirements on the first status of a quest
    return true
  end

  local tvalid = validStatusTable[oldStatus][newStatus]
  if not tvalid then
    return false, string.format("Unexpected status transition: %s -> %s", oldStatus, newStatus)
  end
  if tvalid.valid then
    return true
  else
    return false, tvalid.reason
  end
end

function addon:ValidateQuestStatusChange(quest)
  local oldStatus = statusTracker[quest.questId]
  local ok, reason = addon:IsValidQuestStatusChange(oldStatus, quest.status)
  assert(ok, reason)
  addon.Logger:Trace("QuestStatus change is valid: %s -> %s", oldStatus, quest.status)
end

addon:OnBackendStart(function()
  -- Get the initial status for each quest in the log so we can detect changes
  local quests = addon.QuestLog:FindAll()
  for _, q in ipairs(quests) do
    statusTracker[q.questId] = q.status
  end

  addon.AppEvents:Subscribe("QuestAdded", function(quest)
    statusTracker[quest.questId] = quest.status
  end)
  addon.AppEvents:Subscribe("QuestDeleted", function(quest)
    statusTracker[quest.questId] = nil
  end)
  addon.AppEvents:Subscribe("QuestUpdated", function(quest)
    local oldStatus = statusTracker[quest.questId]
    if oldStatus == quest.status then return end -- No change

    statusTracker[quest.questId] = quest.status
    addon.AppEvents:Publish("QuestStatusChanged", quest, oldStatus)
  end)
end)