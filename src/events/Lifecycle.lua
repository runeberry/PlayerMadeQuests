local _, addon = ...
addon.Lifecycle = addon.Events:CreateBroker("Lifecycle")

local events = {
  AddonLoaded = "AddonLoaded",
  SaveDataLoaded = "SaveDataLoaded",
  ConfigLoaded = "ConfigLoaded",
  AddonConfigured = "AddonConfigured",
  AddonReady = "AddonReady",
}
addon.LifecycleEvents = events

local lifecycleEventsPublished = {}

local function publish(event)
  lifecycleEventsPublished[event] = true
  addon.Lifecycle:Publish(event)
end

function addon.Lifecycle:Start()
  publish(events.AddonLoaded)
  addon.SaveData:Init()
  publish(events.SaveDataLoaded)
  addon.Config:Init()
  publish(events.ConfigLoaded)
  publish(events.AddonConfigured)
  publish(events.AddonReady)
end

function addon.Lifecycle:OnSubscribe(event, handler)
  if lifecycleEventsPublished[event] then
    -- Lifecycle events are only published once, so if a handler is subscribed
    -- after the event has been published, simply run the handler immediately.

    -- todo: This was copied from EventsCore, should probably make this code
    -- accessible to individual brokers.
    local logLevel = addon.LogLevel.trace
    if handler.logLevel then
      logLevel = handler.logLevel
    end
    self.logger:Log(logLevel, "Handling %s: %s", self.name, event)
    addon:catch(handler.fn)
    return false -- Do not continue with the subscription
  end
end

-- Create shortcut methods on the addon for each Lifecycle event.
-- For example - addon:OnSaveDataLoaded == addon.Lifecycle:Subscribe("SaveDataLoaded")
for _, event in pairs(events) do
  addon["On"..event] = function(self, handlerFunc, options)
    addon.Lifecycle:Subscribe(event, handlerFunc, options)
  end
end
