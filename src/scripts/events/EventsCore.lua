local _, addon = ...
addon:traceFile("EventsCore.lua")

addon.Events = {}
local keyCounter = 0

local function getHandlerKey()
  -- A global static counter is sufficient for generating unique handler indices
  keyCounter = keyCounter + 1
  -- String index will prevent reindexing when an item is removed from a table
  return tostring(keyCounter)
end

function addon.Events:CreateBroker()
  local broker = {
    handlersMap = {},
    logLevel = addon.LogLevel.trace, -- Default log level for tracking that an event was received
    logLevelNoHandlers = addon.LogLevel.none -- Log level for event received w/ no subscribers
  }

  function broker:Publish(event, ...)
    local handlers = self.handlersMap[event]
    if addon:tlen(handlers) == 0 then
      -- There are no handlers registered for this event
      addon:log(self.logLevelNoHandlers, "Attempted to handle", event, "event, but there are no subscribers")
      return
    else
      for _, handler in pairs(handlers) do
        local logLevel = self.logLevel
        if handler.logLevel then
          -- If the handler has a log level, then override the broker's default log level
          logLevel = handler.logLevel
        end
        addon:log(logLevel, "Publishing event:", event)
        if self.OnPublish then
          -- todo: OnPublish is not wrapped in a catch
          addon:catch(handler.fn, self:OnPublish(...))
        else
          addon:catch(handler.fn, ...)
        end
      end
    end
  end

  function broker:Subscribe(event, handlerFunc, options)
    local handler = {
      fn = handlerFunc
    }

    if options then
      if options.logLevel then
        handler.logLevel = options.logLevel
      end
    end

    if broker.OnSubscribe then
      broker:OnSubscribe(event, handler)
    end

    local handlers = self.handlersMap[event]
    if handlers == nil then
      -- If this is the first handler registered to this event, then
      -- create a new table to store handlers
      handlers = {}
      self.handlersMap[event] = handlers
    end

    local key = getHandlerKey()
    handlers[key] = handler
    addon:log(self.logLevel, "Subscribed to event:", event)
    return key -- Key can be used to unsubscribe later
  end

  function broker:Unsubscribe(event, key)
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

    table.remove(handlers, key)

    if addon:tlen(handlers) == 0 then
      -- If this was the last subscriber for this event, remove the event from the handlersMap
      table.remove(self.handlersMap, event)
    end

    return true
  end

  return broker
end
