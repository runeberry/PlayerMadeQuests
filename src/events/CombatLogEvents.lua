local _, addon = ...

local CombatLogGetCurrentEventInfo = addon.G.CombatLogGetCurrentEventInfo

addon.CombatLogEvents = addon.Events:CreateBroker("CombatLogEvent")

-- Returns only the event type of the current combat log event
-- function addon:GetClogEventType()
--   local _, event = CombatLogGetCurrentEventInfo()
--   return event
-- end

-- Returns the current combat log event info as a parsed object
-- Also adds some useful fields derived from this info
-- This object will be provided as the only parameter to functions
--   registered in PmqCombatLogEvents.lua
local function getClog()
  local info = { CombatLogGetCurrentEventInfo() }
  local obj = {
    raw = info,
    timestamp = info[1],
    event = info[2],
    hideCaster = info[3],
    sourceGuid = info[4],
    sourceName = info[5],
    sourceFlags = info[6],
    sourceRaidFlags = info[7],
    destGuid = info[8],
    destName = info[9],
    destFlags = info[10],
    destRaidFlags = info[11]
  }

  return obj
end

addon:OnBackendStart(function()
  -- This function can be used to pipe Publish events from the Game Events broker
  -- this this broker's Publish function, whenever a CLEU event is captured
  local function wrapGameEventPublish()
    -- todo: (#47) Should optimize this by only parsing combat logs
    -- when we know there is a subscription for this combat log event
    -- https://github.com/dolphinspired/PlayerMadeQuests/issues/47
    local cl = getClog()
    addon.CombatLogEvents:Publish(cl.event, cl)
  end
  addon.GameEvents:Subscribe("COMBAT_LOG_EVENT_UNFILTERED", wrapGameEventPublish, { logLevel = addon.LogLevel.none, sync = true })
end)