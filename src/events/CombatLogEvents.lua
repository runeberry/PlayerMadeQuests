local _, addon = ...
addon:traceFile("CombatLogEvents.lua")

addon.CombatLogEvents = addon.Events:CreateBroker("CombatLogEvent")
addon.CombatLogEvents.logLevelHandle = addon.LogLevel.trace

function addon.CombatLogEvents:Start()
  if self.started then
    -- Only allow Start to run once
    return
  end

  -- This function can be used to pipe Publish events from the Game Events broker
  -- this this broker's Publish function, whenever a CLEU event is captured
  local function wrapGameEventPublish()
    addon.CombatLogEvents:Publish(addon:GetClogEventType())
  end
  addon.GameEvents:Subscribe("COMBAT_LOG_EVENT_UNFILTERED", wrapGameEventPublish, { logLevel = addon.LogLevel.none })
  self.started = true
end

function addon.CombatLogEvents:OnPublish()
  -- All events registered with this broker will get one arg, and that is a parsed combat log event
  return addon:GetClog()
end

addon:onload(function()
  addon.CombatLogEvents:Start()
end)