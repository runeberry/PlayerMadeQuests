local _, addon = ...
addon:traceFile("EventsCore.lua")

local unpack = addon.G.unpack

addon.Events = {}
local processDelayMs = 0.033 -- approximately 1 frame @ 30 FPS

local function processQueue(broker)
  broker.pubFlag = false
  for event, payloadArray in pairs(broker.queue) do
    broker.queue[event] = nil -- immediately remove from queue so it doesn't get reprocessed
    local subscriberFuncs = broker.handlersMap[event]
    if addon:tlen(subscriberFuncs) == 0 then
      -- There are no handlers registered for this event
      addon:log(broker.logLevelNoHandlers, "Attempted to handle", event, "event, but there are no subscribers")
    else
      for _, payload in pairs(payloadArray) do
        for _, handler in pairs(subscriberFuncs) do
          local logLevel = broker.logLevelHandle
          if handler.logLevel then
            -- If the handler has a log level, then override the broker's default log level
            logLevel = handler.logLevel
          end
          addon:log(logLevel, "Handling "..broker.name..":", event)
          if broker.OnPublish then
            -- todo: OnPublish is not wrapped in a catch
            addon:catch(handler.fn, broker:OnPublish(unpack(payload)))
          else
            addon:catch(handler.fn, unpack(payload))
          end
        end
      end
    end
  end
end

local function broker_Publish(self, event, ...)
  addon:log(self.logLevelPublish, "Publishing "..self.name..":", event)
  local handlers = self.handlersMap[event]
  if addon:tlen(handlers) == 0 then
    -- There are no handlers registered for this event
    addon:log(self.logLevelNoHandlers, "Attempted to handle", event, "event, but there are no subscribers")
    return
  else
    -- Insert the payload for this event into the queue
    local existing = self.queue[event]
    if existing == nil then
      existing = {}
      self.queue[event] = existing
    end
    table.insert(existing, { ... })

    if not self.pubFlag then
      -- If this is the first event published to this broker (this frame)
      -- then set a timer to process the queue on the next frame (approximately)
      addon.Ace:ScheduleTimer(processQueue, processDelayMs, self)
      self.pubFlag = true
    end
  end
end

local function broker_Subscribe(self, event, handlerFunc, options)
  local handler = {
    fn = handlerFunc
  }

  if options then
    if options.logLevel then
      handler.logLevel = options.logLevel
    end
  end

  if self.OnSubscribe then
    self:OnSubscribe(event, handler)
  end

  local handlers = self.handlersMap[event]
  if handlers == nil then
    -- If this is the first handler registered to this event, then
    -- create a new table to store handlers
    handlers = {}
    self.handlersMap[event] = handlers
  end

  local key = addon:CreateID("subscription-%i")
  handlers[key] = handler
  addon:log(self.logLevelSubscribe, "Subscribed to "..self.name..":", event)
  return key -- Key can be used to unsubscribe later
end

local function broker_Unsubscribe(self, event, key)
  local handlers = self.handlersMap[event]
  if handlers == nil then
    -- No handlers to unsubscribe
    addon:log(self.loglevelNoHandlers, "No handlers to unsubscribe from event:", event)
    return false
  end

  local handler = handlers[key]

  if handler == nil then
    -- No handler subscribed with that key
    addon:log(self.loglevelNoHandlers, "No", event, "handlers to unsubscribe with key:", key)
    return false
  end

  if self.OnUnsubscribe then
    self:OnUnsubscribe(event, handler)
  end

  handlers[key] = nil

  if addon:tlen(handlers) == 0 then
    -- If this was the last subscriber for this event, remove the event from the handlersMap
    self.handlersMap[event] = nil
  end

  addon:log(self.logLevelUnsubscribe, "Unsubscribed from event:", event)
  return true
end

function addon.Events:CreateBroker(name)
  local broker = {
    name = name or "event",
    pubFlag = false,
    queue = {},
    handlersMap = {},
    -- Default log level for tracking that an event was received
    logLevelPublish = addon.LogLevel.none,
    logLevelSubscribe = addon.LogLevel.none,
    logLevelUnsubscribe = addon.LogLevel.none,
    logLevelHandle = addon.LogLevel.none,
    logLevelNoHandlers = addon.LogLevel.none,

    Publish = broker_Publish,
    Subscribe = broker_Subscribe,
    Unsubscribe = broker_Unsubscribe
  }

  return broker
end
