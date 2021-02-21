local _, addon = ...
local asserttype = addon.asserttype
local unpack = addon.G.unpack

addon.Events = {}
local processDelay = 0.033 -- approximately 1 frame @ 30 FPS

local function handleEvent(broker, event, ...)
  for _, handler in pairs(broker._handlersMap[event]) do
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
  local queue = addon:CopyTable(broker._queue)
  broker._queue = {}
  for _, item in ipairs(queue) do
    if broker:GetNumSubscribers(item.event) > 0 then
      handleEvent(broker, item.event, unpack(item.args))
    end
  end
end

local brokerMethods = {
  ["Publish"] = function(self, event, ...)
    self:LogEvent(addon.LogLevel.debug, "Publishing: %s", event)
    local handlers = self._handlersMap[event]
    if addon:tlen(handlers) == 0 then
      -- There are no handlers registered for this event
      return
    elseif self._async then
      -- Async event handling - set a timer and execute events on the next frame
      -- Insert the payload for this event into the queue
      self._queue[#self._queue+1] = {
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
      if self:GetNumSubscribers(event) > 0 then
        handleEvent(self, event, ...)
      end
    end
  end,
  ["Subscribe"] = function(self, event, handlerFunc, options)
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

    local handlers = self._handlersMap[event]
    if handlers == nil then
      -- If this is the first handler registered to this event, then
      -- create a new table to store handlers
      handlers = {}
      self._handlersMap[event] = handlers
    end

    local key = addon:CreateID("subscription-%i")
    handlers[key] = handler
    self:LogEvent(addon.LogLevel.trace, "Subscribe: %s", event)
    return key -- Key can be used to unsubscribe later
  end,
  ["Unsubscribe"] = function(self, event, key)
    local handlers = self._handlersMap[event]
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
      self._handlersMap[event] = nil
    end

    self:LogEvent(addon.LogLevel.trace, "Unsubscribe: %s", event)
    return true
  end,

  -- This will take effect the next time an event is published
  ["EnableAsync"] = function(self, bool)
    if bool == nil then bool = true end
    self._async = bool
  end,
  ["GetNumSubscribers"] = function(self, event)
    return addon:tlen(self._handlersMap[event])
  end,

  ["SetLogLevel"] = function(self, loglevel)
    self._logger:SetLogLevel(loglevel)
  end,
  ["ExcludeFromLogging"] = function(self, ...)
    for _, event in ipairs({ ... }) do
      self._logBlacklist[event] = true
    end
  end,
  ["LogEvent"] = function(self, logLevel, message, event)
    if self._logBlacklist[event] then return end
    self._logger:Log(logLevel, message, event)
  end,
}

function addon.Events:CreateBroker(name)
  asserttype(name, "string")

  local broker = {
    _name = name or "Event",
    _pubFlag = false,
    _async = false,
    _logger = addon.Logger:NewLogger(name),
    _logBlacklist = {},
    _queue = {},
    _handlersMap = {},
  }

  addon:ApplyMethods(broker, brokerMethods)

  return broker
end
