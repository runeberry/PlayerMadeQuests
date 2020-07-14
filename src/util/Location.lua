local _, addon = ...
local logger = addon.Logger:NewLogger("Location")

local GetBestMapForUnit = addon.G.GetBestMapForUnit
local GetPlayerMapPosition = addon.G.GetPlayerMapPosition
local GetRealZoneText = addon.G.GetRealZoneText
local GetSubZoneText = addon.G.GetSubZoneText
local GetMinimapZoneText = addon.G.GetMinimapZoneText
local GetZoneText = addon.G.GetZoneText

local playerLocation

local pollingIds = {}
local pollingTimerId
local pollingTimerInterval = 1 -- time between polling events in seconds

function addon:GetPlayerLocation(refresh)
  if playerLocation and not refresh then
    return playerLocation
  end

  local map = GetBestMapForUnit("player")
  local x, y = 0, 0
  if map then
    local position = GetPlayerMapPosition(map, "player")
    x, y = position:GetXY()
  end

  local loc = {
    zone = GetZoneText(),
    realZone = GetRealZoneText(),
    subZone = GetSubZoneText(),
    minimapZone = GetMinimapZoneText(),
    x = x * 100,
    y = y * 100
  }

  local doPublish = false
  if playerLocation then
    if playerLocation.x ~= loc.x or playerLocation.y ~= loc.y then
      doPublish = true
    end
  end

  playerLocation = loc

  if doPublish then
    addon.AppEvents:Publish("PlayerLocationChanged", playerLocation)
    logger:Trace("Player location changed")
  end

  return playerLocation
end

function addon:CheckPlayerInZone(zone, refresh)
  local ld = addon:GetPlayerLocation(refresh)
  return ld.zone == zone or ld.realZone == zone or ld.subZone == zone or ld.minimapZone == zone
end

local function pollingFn()
  addon:GetPlayerLocation(true)
end

-- Give an id to indicate the thing you're polling the player's location for
function addon:StartPollingLocation(id)
  pollingIds[id] = true
  -- If polling has already started, don't try to start it again
  if pollingTimerId then return end
  pollingTimerId = addon.Ace:ScheduleRepeatingTimer(pollingFn, pollingTimerInterval)
  logger:Trace("Start polling for player location")
end

-- Give an id to indicate what you no longer need to poll the player's location for
-- Polling will only stop when all ids have been stopped
function addon:StopPollingLocation(id)
  pollingIds[id] = nil
  -- If there are other objectives being polled for, don't try to cancel polling
  if addon:tlen(pollingIds) > 0 then return end
  -- If the polling has already been canceled, don't try to cancel it again
  if not pollingTimerId then return end
  addon.Ace:CancelTimer(pollingTimerId)
  pollingTimerId = nil
  logger:Trace("Stop polling for player location")
end

-- Emergency brake
function addon:StopAllLocationPolling()
  if not pollingTimerId then return end
  addon.Ace:CancelTimer(pollingTimerId)
  pollingTimerId = nil
  pollingIds = {}
  logger:Trace("Stop polling for player location")
end