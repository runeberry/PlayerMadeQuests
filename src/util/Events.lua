local _, addon = ...

local unpack = addon.G.unpack

addon.Events = {}
local processDelay = 0.033 -- approximately 1 frame @ 30 FPS

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
    broker:LogEvent(logLevel, "Handling: %s", event)
    addon:catch(handler.fn, ...)
  end
end

local function processQueue(broker)
  broker._pubFlag = false
  local queue = addon:CopyTable(broker.queue)
  broker.queue = {}
  for _, item in ipairs(queue) do
    if checkHasSubscribers(broker, item.event) then
      handleEvent(broker, item.event, unpack(item.args))
    end
  end
end

local function broker_Publish(self, event, ...)
  self:LogEvent(addon.LogLevel.debug, "Publishing: %s", event)
  local handlers = self.handlersMap[event]
  if addon:tlen(handlers) == 0 then
    -- There are no handlers registered for this event
    return
  elseif self._async then
    -- Async event handling - set a timer and execute events on the next frame
    -- Insert the payload for this event into the queue
    self.queue[#self.queue+1] = {
      event = event,
      args = { ... }
    }

    if not self._pubFlag then
      -- If this is the first event published to this broker (this frame)
      -- then set a timer to process the queue on the next frame (approximately)
      addon.Ace:ScheduleTimer(processQueue, processDelay, self)
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
    -- If the OnSubscribe handler returns false, do not subscribe the handler
    local result = self:OnSubscribe(event, handler)
    if result == false then return end
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
  self:LogEvent(addon.LogLevel.trace, "Subscribe: %s", event)
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

  self:LogEvent(addon.LogLevel.trace, "Unsubscribe: %s", event)
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

local function broker_ExcludeFromLogging(self, ...)
  for _, event in ipairs({ ... }) do
    self.logBlacklist[event] = true
  end
end

local function broker_LogEvent(self, logLevel, message, event)
  if self.logBlacklist[event] then return end
  self.logger:Log(logLevel, message, event)
end

function addon.Events:CreateBroker(name)
  local broker = {
    name = name or "Event",
    _pubFlag = false,
    _async = false,
    logger = addon.Logger:NewLogger(name),
    logBlacklist = {},
    queue = {},
    handlersMap = {},

    Publish = broker_Publish,
    Subscribe = broker_Subscribe,
    Unsubscribe = broker_Unsubscribe,

    EnableAsync = broker_EnableAsync,
    SetLogLevel = broker_SetLogLevel,
    ExcludeFromLogging = broker_ExcludeFromLogging,
    LogEvent = broker_LogEvent,
  }

  return broker
end
