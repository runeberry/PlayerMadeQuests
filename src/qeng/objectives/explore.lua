local _, addon = ...
addon:traceFile("objectives/explore.lua")
local compiler, tokens = addon.QuestScriptCompiler, addon.QuestScript.tokens

local GetBestMapForUnit = addon.G.GetBestMapForUnit
local GetPlayerMapPosition = addon.G.GetPlayerMapPosition
local GetRealZoneText = addon.G.GetRealZoneText
local GetSubZoneText = addon.G.GetSubZoneText
local GetMinimapZoneText = addon.G.GetMinimapZoneText
local GetZoneText = addon.G.GetZoneText

local defaultRadius = 0.5
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

local function setRadius(obj)
  if obj._didSetRadius then return end
  local radius = obj:GetConditionValue(tokens.PARAM_RADIUS) or defaultRadius
  obj:SetMetadata("PlayerLocationRadius", radius)
  obj._didSetRadius = true
end

compiler:AddScript(tokens.OBJ_EXPLORE, tokens.METHOD_PRE_COND, function(obj, locData)
  setRadius(obj)
  obj:SetMetadata("PlayerLocationData", locData)
end)

compiler:AddScript(tokens.OBJ_EXPLORE, tokens.METHOD_POST_COND, function(obj)
  obj:SetMetadata("PlayerLocationData", nil)

  if obj:HasCondition(tokens.PARAM_POSX) or obj:HasCondition(tokens.PARAM_POSY) then
    -- If the objective specifies an X or Y position, then begin polling for X/Y changes
    -- on an interval whenever a player enters the correct zone
    local inZone, inSubZone
    if obj:HasCondition(tokens.PARAM_ZONE) then
      inZone = obj:GetMetadata("PlayerIsInZone")
    else
      inZone = true
    end
    if obj:HasCondition(tokens.PARAM_SUBZONE) then
      inSubZone = obj:GetMetadata("PlayerIsInSubZone")
    else
      inSubZone = true
    end
    if inZone and inSubZone then
      startPolling(obj)
    else
      stopPolling(obj)
    end
  end
end)

compiler:AddScript(tokens.OBJ_EXPLORE, tokens.METHOD_DISPLAY_TEXT, function(obj)
  local text = "Go to"

  local hasCoords = obj:HasCondition(tokens.PARAM_POSX) and obj:HasCondition(tokens.PARAM_POSY)
  if hasCoords then
    local x, y = obj:GetConditionDisplayText(tokens.PARAM_POSX), obj:GetConditionDisplayText(tokens.PARAM_POSY)
    text = text..string.format(" (%s, %s)", x, y)
  end
  local hasSub = obj:HasCondition(tokens.PARAM_SUBZONE)
  if hasSub then
    if hasCoords then
      text = text.." in"
    end
    text = text.." "..obj:GetConditionDisplayText(tokens.PARAM_SUBZONE)
  end
  local hasZone = obj:HasCondition(tokens.PARAM_ZONE)
  if hasZone then
    if hasCoords or hasSub then
      text = text.." in"
    end
    text = text.." "..obj:GetConditionDisplayText(tokens.PARAM_ZONE)
  end
  return text
end)

local function publish()
  local map = GetBestMapForUnit("player")
  local x, y = 0, 0
  if map then
    local position = GetPlayerMapPosition(map, "player")
    x, y = position:GetXY()
  end

  local ld = {
    zone = GetZoneText(),
    realZone = GetRealZoneText(),
    subZone = GetSubZoneText(),
    minimapZone = GetMinimapZoneText(),
    x = x * 100,
    y = y * 100
  }
  addon.QuestEvents:Publish(tokens.OBJ_EXPLORE, ld)
end

addon:onload(function()
  pollingFn = publish
  addon.AppEvents:Subscribe("QuestAdded", publish)
  addon.AppEvents:Subscribe("QuestLogBuilt", publish)
  addon.AppEvents:Subscribe("QuestTrackingStarted", publish)
  addon.GameEvents:Subscribe("ZONE_CHANGED", publish)
  addon.GameEvents:Subscribe("ZONE_CHANGED_INDOORS", publish)
  addon.GameEvents:Subscribe("ZONE_CHANGED_NEW_AREA", publish)
  addon.AppEvents:Subscribe("ObjectiveCompleted", stopPolling)
end)