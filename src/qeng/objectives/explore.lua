local _, addon = ...
addon:traceFile("objectives/explore.lua")
local compiler, tokens = addon.QuestScriptCompiler, addon.QuestScript.tokens

local pollingFn
local pollingObjectives = {}
local pollingTimerId
local pollingTimerInterval = 1

local function startPolling(obj)
  -- Indicate that this objective is being polled for
  pollingObjectives[obj.id] = true
  -- If polling has already started, don't try to start it again
  if pollingTimerId then return end
  pollingTimerId = addon.Ace:ScheduleRepeatingTimer(pollingFn, pollingTimerInterval)
  addon.Logger:Trace("Start polling for player location")
end

local function stopPolling(obj)
  -- Indicate that this objective is no longer being polled for
  pollingObjectives[obj.id] = nil
  -- If there are other objectives being polled for, don't try to cancel polling
  if addon:tlen(pollingObjectives) > 0 then return end
  -- If the polling has already been canceled, don't try to cancel it again
  if not pollingTimerId then return end
  addon.Ace:CancelTimer(pollingTimerId)
  pollingTimerId = nil
  addon.Logger:Trace("Stop polling for player location")
end

compiler:AddScript(tokens.OBJ_EXPLORE, tokens.METHOD_POST_COND, function(obj, result, locData)
  if obj.conditions[tokens.PARAM_POSX] or obj.conditions[tokens.PARAM_POSY] then
    -- If the objective specifies an X or Y position, then begin polling for X/Y changes
    -- on an interval whenever a player enters the correct zone(s)
    local z, sz = obj.conditions[tokens.PARAM_ZONE], obj.conditions[tokens.PARAM_SUBZONE]
    local inZone = (not z) or addon:CheckPlayerInZone(z)
    local inSubZone = (not sz) or addon:CheckPlayerInZone(sz)

    if inZone and inSubZone then
      startPolling(obj)
    else
      stopPolling(obj)
    end
  end
end)

local function publish()
  -- Calling GPL(true) here will ensure the data is refreshed for all conditions
  addon.QuestEvents:Publish(tokens.OBJ_EXPLORE, addon:GetPlayerLocation(true))
end

addon:onload(function()
  addon.AppEvents:Subscribe("QuestAdded", publish)
  addon.AppEvents:Subscribe("QuestLogBuilt", publish)
  addon.AppEvents:Subscribe("QuestTrackingStarted", publish)
  addon.GameEvents:Subscribe("ZONE_CHANGED", publish)
  addon.GameEvents:Subscribe("ZONE_CHANGED_INDOORS", publish)
  addon.GameEvents:Subscribe("ZONE_CHANGED_NEW_AREA", publish)

  pollingFn = publish
  addon.AppEvents:Subscribe("ObjectiveCompleted", stopPolling)
end)