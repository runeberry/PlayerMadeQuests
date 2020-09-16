local _, addon = ...
addon.Lifecycle = addon.Events:CreateBroker("Lifecycle")

local events = {
  AddonStart = "OnAddonStart",
  SaveDataLoaded = "OnSaveDataLoaded",
  ConfigLoaded = "OnConfigLoaded",
  BackendStart = "OnBackendStart",
  QuestEngineReady = "OnQuestEngineReady",
  QuestTrackingReady = "OnQuestTrackingReady",
  BackendReady = "OnBackendReady",
  GuiStart = "OnGuiStart",
  GuiReady = "OnGuiReady",
  AddonReady = "OnAddonReady",
}
addon.LifecycleEvents = events

local lifecycleEventsPublished = {}

-- Create shortcut methods on the addon for each Lifecycle event.
-- For example - addon:OnSaveDataLoaded == addon.Lifecycle:Subscribe("OnSaveDataLoaded")
for _, event in pairs(events) do
  addon[event] = function(self, handlerFunc, options)
    addon.Lifecycle:Subscribe(event, handlerFunc, options)
  end
end

local function publish(event)
  lifecycleEventsPublished[event] = true
  addon.Lifecycle:Publish(event)
end

function addon.Lifecycle:Init()
  publish(events.AddonStart)

  addon.SaveData:Init()
  publish(events.SaveDataLoaded)
  addon.Config:Init()
  addon.Logger:Init()
  addon.Data:Init()
  publish(events.ConfigLoaded)

  addon:RunAddonMigrations()
  addon:RunQuestMigrations()

  publish(events.BackendStart)
  addon.QuestEngine:Init()
  publish(events.QuestEngineReady)
  addon.QuestEngine:StartTrackingQuestLog()
  publish(events.QuestTrackingReady)
  publish(events.BackendReady)

  if addon.Config:GetValue("ENABLE_GUI") then
    publish(events.GuiStart)
    publish(events.GuiReady)
  end

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
    self.logger:Log(logLevel, "Handling: %s", event)
    addon:catch(handler.fn)
    return false -- Do not continue with the subscription
  end
end
