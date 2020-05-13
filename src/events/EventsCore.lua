local _, addon = ...
addon:traceFile("EventsCore.lua")

local unpack = addon.G.unpack

addon.Events = {}
local processDelayMs = 0.033 -- approximately 1 frame @ 30 FPS

local function checkHasSubscribers(broker, event)
  if addon:tlen(broker.handlersMap[event]) == 0 then
    -- There are no handlers registered for this event
    return false
  end
  return true
end

local function handleEvent(broker, event, ...)
  for _, handler in pairs(broker.handlersMap[event]) do
    local logLevel = addon.LogLevel.trace
    if handler.logLevel then
      -- If the handler has a log level, then override the broker's default log level
      logLevel = handler.logLevel
    end
    broker.logger:log(logLevel, "Handling "..broker.name..":", event)
    addon:catch(handler.fn, ...)
  end
end

local function processQueue(broker)
  broker._pubFlag = false
  for event, payloadArray in pairs(broker.queue) do
    broker.queue[event] = nil -- immediately remove from queue so it doesn't get reprocessed
    if checkHasSubscribers(broker, event) then
      for _, payload in pairs(payloadArray) do
        handleEvent(broker, event, unpack(payload))
      end
    end
  end
end

local function broker_Publish(self, event, ...)
  self.logger:trace("Publishing "..self.name..":", event)
  local handlers = self.handlersMap[event]
  if addon:tlen(handlers) == 0 then
    -- There are no handlers registered for this event
    return
  elseif self._async then
    -- Async event handling - set a timer and execute events on the next frame
    -- Insert the payload for this event into the queue
    local existing = self.queue[event]
    if existing == nil then
      existing = {}
      self.queue[event] = existing
    end
    table.insert(existing, { ... })

    if not self._pubFlag then
      -- If this is the first event published to this broker (this frame)
      -- then set a timer to process the queue on the next frame (approximately)
      addon.Ace:ScheduleTimer(processQueue, processDelayMs, self)
      self._pubFlag = true
    end
  else
    -- Sync event handling - run all handlers as soon as the event is published
    if checkHasSubscribers(self, event) then
      handleEvent(self, event, ...)
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
  self.logger:trace("Subscribed to "..self.name..":", event)
  return key -- Key can be used to unsubscribe later
end

local function broker_Unsubscribe(self, event, key)
  local handlers = self.handlersMap[event]
  if handlers == nil then
    -- No handlers to unsubscribe
    return false
  end

  local handler = handlers[key]

  if handler == nil then
    -- No handler subscribed with that key
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

  self.logger:trace("Unsubscribed from event:", event)
  return true
end

-- This will take effect the next time an event is published
local function broker_EnableAsync(self, bool)
  if bool == nil then bool = true end
  self._async = bool
end

local function broker_SetLogLevel(self, loglevel)
  self.logger:SetLogLevel(loglevel)
end

function addon.Events:CreateBroker(name)
  local broker = {
    name = name or "event",
    _pubFlag = false,
    _async = false,
    logger = addon:NewLogger(),
    queue = {},
    handlersMap = {},

    Publish = broker_Publish,
    Subscribe = broker_Subscribe,
    Unsubscribe = broker_Unsubscribe,

    EnableAsync = broker_EnableAsync,
    SetLogLevel = broker_SetLogLevel,
  }

  return broker
end
