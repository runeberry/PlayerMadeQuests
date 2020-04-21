local _, addon = ...
addon:traceFile("PmqStart.lua")

function PMQ_EventFrame_OnLoad(self)
  if addon.events == nil then
    error("Addon events did not load, check PmqEvents.lua")
  end

  -- Must explicitly declare addon.events as 'self' for the class method
  addon:catch(addon.events.registerEventsToFrame, addon.events, self)
end

function PMQ_EventFrame_OnEvent(self, event, ...)
  if addon.events == nil then
    error("Addon events did not load, check PmqEvents.lua")
  end

  -- Must explicitly declare addon.events as 'self' for the class method
  addon:catch(addon.events.onGameEvent, addon.events, event, ...)
end

addon.events:addOnLoadHandler(function()
  addon:info("PMQ Loaded")
end)