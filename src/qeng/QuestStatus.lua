local _, addon = ...

-- Keep track of the status changes of each quest and react accordingly
local statusTracker = {}

local qs = {
  Active = "Active",
  Failed = "Failed",
  Abandoned = "Abandoned",
  Completed = "Completed",
  Finished = "Finished",
  Archived = "Archived",
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
    [qs.Completed] = valid(),
    [qs.Finished] = invalid("A quest can only be finished from the Completed status."),
    [qs.Archived] = valid(),
  },
  [qs.Failed] = {
    [qs.Active] = valid(),
    [qs.Failed] = valid(),
    [qs.Abandoned] = valid(),
    [qs.Completed] = invalid("A quest can only be completed from the Active status."),
    [qs.Finished] = invalid("A quest can only be finished from the Completed status."),
    [qs.Archived] = valid(),
  },
  [qs.Abandoned] = {
    [qs.Active] = valid(),
    [qs.Failed] = invalid("A quest can only be failed from the Active status."),
    [qs.Abandoned] = valid(),
    [qs.Completed] = invalid("A quest can only be completed from the Active status."),
    [qs.Finished] = invalid("A quest can only be finished from the Completed status."),
    [qs.Archived] = valid(),
  },
  [qs.Completed] = {
    [qs.Active] = valid(),
    [qs.Failed] = invalid("A quest can only be failed from the Active status."),
    [qs.Abandoned] = valid(),
    [qs.Completed] = valid(),
    [qs.Finished] = valid(),
    [qs.Archived] = valid(),
  },
  [qs.Finished] = {
    [qs.Active] = valid(),
    [qs.Failed] = invalid("A quest can only be failed from the Active status."),
    [qs.Abandoned] = invalid("A finished quest cannot be returned to the Abandoned status."),
    [qs.Completed] = invalid("A finished quest cannot be returned to the Completed status."),
    [qs.Finished] = valid(),
    [qs.Archived] = valid(),
  },
  [qs.Archived] = {
    [qs.Active] = valid(),
    [qs.Failed] = invalid("A quest can only be failed from the Active status."),
    [qs.Abandoned] = invalid("A quest cannot be abandoned once it's already been archived."),
    [qs.Completed] = valid(),
    [qs.Finished] = valid(),
    [qs.Archived] = valid(),
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
  if not ok then
    error(reason)
  end
end

addon:onload(function()
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
  addon.AppEvents:Subscribe("QuestDataLoaded", function()
    local quests = addon.QuestLog:FindAll()
    for _, q in ipairs(quests) do
      statusTracker[q.questId] = q.status
    end
  end)
end)