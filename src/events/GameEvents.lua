local _, addon = ...

-- Note that this event should NOT be executed async, because some global functions only return
-- correct data on the same frame that the event is fired
addon.GameEvents = addon.Events:CreateBroker("GameEvent")

-- This function can be used to pipe Event API events to this broker's Publish function
local function wrapPublish(event, ...)
  addon.GameEvents:Publish(event, ...)
end

function addon.GameEvents:OnSubscribe(event)
  if self.handlersMap[event] == nil then
    -- If this is the first subscriber for this event, register it with Ace
    addon.Ace:RegisterEvent(event, wrapPublish)
  end
end

function addon.GameEvents:OnUnsubscribe(event)
  local handlers = self.handlersMap[event]
  if addon:tlen(handlers) == 1 then
    -- If this is the last subscriber for this event, unregister it from Ace
    addon.Ace:UnregisterEvent(event)
  end
end

-- Helper function to subscribe to ALL known game events.
-- Enable debug logs on PMQ:GameEvent to see what's being captured.
local watchAllSubKeys
function addon.GameEvents:ToggleWatchAll()
  if watchAllSubKeys then
    -- Events are already subscribed, unsubscribe from them
    for event, key in pairs(watchAllSubKeys) do
      self:Unsubscribe(event, key)
    end
    watchAllSubKeys = nil
    addon.Logger:Warn("GameEvent scanning disabled.")
  else
    -- Events have not yet been subscribed, subscribe to them here
    watchAllSubKeys = {}
    local handler = function() end
    for _, event in ipairs(addon.GameEventsList) do
      -- Subscribe to the event and store the key to unsubscribe from it later
      watchAllSubKeys[event] = self:Subscribe(event, handler)
    end
    addon.Logger:Warn("GameEvent scanning enabled. (%i events)", #addon.GameEventsList)
  end
end