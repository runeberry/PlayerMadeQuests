local _, addon = ...
local ll = addon.LogLevel
addon:traceFile("PmqEvents.lua")

local events = {
  gameEventsMap = {},
  combatLogEventsMap = {},
  loaded = false
}

local function makeHandlerTemplate(fn)
  -- TODO: Add debugging features like call counter, log settings, etc.
  return {
    fn = fn,
    logLevel = ll.debug -- log level for root handler only
  }
end

-- Root handler for all game events
local function onGameEvent(event, ...)
  local handlers = events.gameEventsMap[event]
  if addon:tlen(handlers) == 0 then
    -- This shouldn't happen, but this condition would be reached if a game event
    -- was registered to a frame without providing a handler
    addon:warn("Attempted to handle", event, "event, but no handlers are registered")
  else
    -- Process the registered handlers in the order that they were added
    for _, handler in pairs(handlers) do
      addon:log(handler.logLevel, "Handling game event:", event)
      addon:catch(handler.fn, ...)
    end
  end
end

-- Root handler for all COMBAT_LOG_EVENT_UNFILTERED events
local function onCombatLogEvent(...)
  local event = addon:GetClogEventType()
  local handlers = events.combatLogEventsMap[event]
  if addon:tlen(handlers) == 0 then
    -- No handlers are registered for this combat log event, which is fine
    return
  else
    local cl = addon:GetClog()
    -- Process the registered handlers in the order that they were added
    for _, handler in pairs(handlers) do
      addon:log(handler.logLevel, "Handling combat event:", event)
      handler.fn(cl) -- errors will be caught by the root game event handler
    end
  end
end

-- Adds a function handle the specified Event API event
function events:addGameEventHandler(event, fn, options)
  if self.loaded then
    -- Events are currently set up to only be registered to the frame once,
    -- when the addon is loaded. This could be changed if needed.
    addon:warn("Game events cannot be registered at this time")
  else
    local gem = events.gameEventsMap
    if gem[event] == nil then
      -- If this is the first handler registered to this event, then
      -- create a new table to store handlers
      gem[event] = {}
    end

    -- Add the handler to the list for this event. If there are multiple
    -- handlers added for an event, they will be processed in the order
    -- in which they were added.
    local handler = makeHandlerTemplate(fn)
    if options then
      if options.logLevel then
        handler.logLevel = options.logLevel
      end
    end
    table.insert(gem[event], handler)
    addon:trace("Added handler for game event:", event)
  end
end

-- Adds a function to handle the specified COMBAT_LOG_EVENT
function events:addCombatLogEventHandler(event, fn)
  -- Combat events can be registered after the addon is loaded because they
  -- do not need to be bound to a frame
  local cem = events.combatLogEventsMap
  if cem[event] == nil then
    -- If this is the first handler registered to this event, then
    -- create a new table to store handlers
    cem[event] = {}
  end

  -- Add the handler to the list for this event. If there are multiple
  -- handlers added for an event, they will be processed in the order
  -- in which they were added.

  -- TODO: support handler options, once we have any to apply to combat events
  table.insert(cem[event], makeHandlerTemplate(fn))
  addon:trace("Added handler for combat log event:", event)
end

function events:registerAceEvents()
  for event, _ in pairs(events.gameEventsMap) do
    addon.Ace:RegisterEvent(event, onGameEvent)
    addon:trace("Registered Ace event:", event)
  end
  events.loaded = true
end

events:addGameEventHandler("COMBAT_LOG_EVENT_UNFILTERED", onCombatLogEvent, { logLevel = ll.none })

addon.events = events