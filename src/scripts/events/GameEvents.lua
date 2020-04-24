local _, addon = ...
addon:traceFile("GameEvents.lua")

addon.GameEvents = addon.Events:CreateBroker()
addon.GameEvents.logLevelNoHandlers = addon.LogLevel.warn

-- Begins listening for events from WoW's Event API
-- Once started, no new events can be registered
function addon.GameEvents:Start()
  -- This function can be used to pipe Event API events to this broker's Publish function
  local function wrapPublish(event, ...)
    addon.GameEvents:Publish(event, ...)
  end

  for event, _ in pairs(self.handlersMap) do
    addon.Ace:RegisterEvent(event, wrapPublish)
  end
  self.started = true
end

function addon.GameEvents:OnSubscribe()
  if self.started then
    error("Game events cannot be registered at this time")
  end
end