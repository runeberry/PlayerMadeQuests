local _, addon = ...
local logger = addon.Logger:NewLogger("Location")
local time = addon.G.time

local GetBestMapForUnit = addon.G.GetBestMapForUnit
local GetPlayerMapPosition = addon.G.GetPlayerMapPosition
local GetRealZoneText = addon.G.GetRealZoneText
local GetSubZoneText = addon.G.GetSubZoneText
local GetMinimapZoneText = addon.G.GetMinimapZoneText
local GetZoneText = addon.G.GetZoneText

local playerLocation = {}
local playerLocationInterval -- Set from config
local playerLocationTtl -- Set from config
local playerLocationExpires = 0 -- updated when the player location is refreshed

local pollingIds = {}
local pollingTimerId

function addon:GetPlayerLocation()
  assert(playerLocationTtl, "PLAYER_LOCATION_TTL is not set")
  local ts = time()
  if playerLocation.timestamp and ts < playerLocationExpires then
    return playerLocation
  end

  local map = GetBestMapForUnit("player")
  local x, y = 0, 0
  if map then
    local position = GetPlayerMapPosition(map, "player")
    if position then
      x, y = position:GetXY()
    end
    -- If you can't get the map position, then player is just assumed to be at 0,0
  end

  -- Reuse the same table for tracking player info, since this is called frequently
  playerLocation.timestamp = ts
  playerLocation.zone = GetZoneText()
  playerLocation.realZone = GetRealZoneText()
  playerLocation.subZone = GetSubZoneText()
  playerLocation.minimapZone = GetMinimapZoneText()
  playerLocation.x = x * 100
  playerLocation.y = y * 100

  playerLocationExpires = ts + playerLocationTtl


  return playerLocation
end

function addon:CheckPlayerInZone(zone)
  local ld = addon:GetPlayerLocation()
  return ld.zone == zone or ld.realZone == zone or ld.subZone == zone or ld.minimapZone == zone
end

local function pollingFn()
  local oldX, oldY = playerLocation.x, playerLocation.y
  addon:GetPlayerLocation()

  if playerLocation.x ~= oldX or playerLocation.y ~= oldY then
    addon.AppEvents:Publish("PlayerLocationChanged", playerLocation)
    logger:Trace("Player location changed: (%.2f, %.2f)", playerLocation.x, playerLocation.y)
  -- else
  --   logger:Trace("[%i] Player location did not change: (%.2f, %.2f)", time() % 100, playerLocation.x, playerLocation.y)
  end
end

-- Give an id to indicate the thing you're polling the player's location for
function addon:StartPollingLocation(id)
  assert(playerLocationInterval, "PLAYER_LOCATION_INTERVAL is not set")
  pollingIds[id] = true
  -- If polling has already started, don't try to start it again
  if pollingTimerId then return end
  pollingTimerId = addon.Ace:ScheduleRepeatingTimer(pollingFn, playerLocationInterval)
  logger:Debug("Start polling for player location")
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
  logger:Debug("Stop polling for player location")
end

-- Emergency brake
function addon:StopAllLocationPolling()
  if not pollingTimerId then return end
  addon.Ace:CancelTimer(pollingTimerId)
  pollingTimerId = nil
  pollingIds = {}
  logger:Debug("Stop polling for player location")
end

local function stopQuestLocationPolling(quest)
  if not quest or not quest.objectives then return end
  for _, obj in ipairs(quest.objectives) do
    addon:StopPollingLocation(obj.id)
  end
end

addon:OnBackendStart(function()
  playerLocationInterval = addon.Config:GetValue("PLAYER_LOCATION_INTERVAL")
  playerLocationTtl = addon.Config:GetValue("PLAYER_LOCATION_TTL")

  addon.AppEvents:Subscribe("QuestTrackingStopped", stopQuestLocationPolling)
end)