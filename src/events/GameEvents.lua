local _, addon = ...

-- Note that this event should NOT be executed async, because some global functions only return
-- correct data on the same frame that the event is fired
addon.GameEvents = addon.Events:CreateBroker("GameEvent")

-- This function can be used to pipe Event API events to this broker's Publish function
local function wrapPublish(event, ...)
  addon.GameEvents:Publish(event, ...)
end

-- Begins listening for events from WoW's Event API
-- Once started, no new events can be registered
function addon.GameEvents:Start()
  if self.started then
    -- Only allow Start to run once
    return
  end

  for event, _ in pairs(self.handlersMap) do
    addon.Ace:RegisterEvent(event, wrapPublish)
  end
  self.started = true
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

addon:onload(function()
  addon.GameEvents:Start()
end)