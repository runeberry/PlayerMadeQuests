local _, addon = ...
addon.Ace = LibStub("AceAddon-3.0"):NewAddon("PlayerMadeQuests", "AceEvent-3.0")
addon.AceGUI = LibStub("AceGUI-3.0")

function addon.Ace:OnInitialize()
  addon:catch(addon.events.registerAceEvents, addon.events)

  if PlayerMadeQuestsCache.QuestLog == nil then
    PlayerMadeQuestsCache.QuestLog = {}
    return
  end

  addon.qlog:Load()

  if PlayerMadeQuestsCache.ShowDemoFrame then
    addon:showDemoFrame()
  end

  addon:info("PMQ Loaded")
end

function addon.Ace:OnEnable()

end

function addon.Ace:OnDisable()

end

-- Saved variables for persisting settings/quest log on logout
PlayerMadeQuestsGlobalCache = PlayerMadeQuestsGlobalCache or {}
PlayerMadeQuestsCache = PlayerMadeQuestsCache or {}

-- Must provide a log level when using addon:log()
-- Change the MinLogLevel to see more/fewer logs in the game console
addon.LogLevel = {
  fatal = 1,
  error = 2,
  warn = 3,
  info = 4,
  debug = 5,
  trace = 6,
  none = 7
}
local ll = addon.LogLevel
addon.MinLogLevel = ll.info

-- Prints a message to console with respect to MinLogLevel
function addon:log(loglevel, str, ...)
  if loglevel > addon.MinLogLevel then
    return
  end
  local ok, err = pcall(print, "[PMQ]", str, ...)
  if (err) then
    print("[PMQ] Error printing log:", err)
  end
end

-- Shorthand methods for logging
function addon:fatal(str, ...) self:log(ll.fatal, str, ...) end
function addon:error(str, ...) self:log(ll.error, str, ...) end
function addon:warn(str, ...) self:log(ll.warn, str, ...) end
function addon:info(str, ...) self:log(ll.info, str, ...) end
function addon:debug(str, ...) self:log(ll.debug, str, ...) end
function addon:trace(str, ...) self:log(ll.trace, str, ...) end

-- Place at the top of a file to help debugging in trace mode
function addon:traceFile(filename)
  addon:trace("File loaded:", filename)
end

-- This is the earliest that this log statement can be called
addon:traceFile("PmqCore.lua")

-- Prints variadic args in one line to the console
-- this is not performant! only use for troubleshooting
function addon:pvargs(...)
  if ll.trace > addon.MinLogLevel then
    -- Check log level before parsing, to save some performance
    return
  end
  local vals = {}
  for n=1, select('#', ...) do
    local val = select(n, ...)
    vals[#vals+1] = tostring(val)
  end
  addon:trace("Variadic args: [" .. table.concat(vals, ", ") .. "]")
end

-- Converts an array (1D table) to a string for quick logging
-- Just tostring-ing the table doesn't seem to work if the inner values are not strings
function addon:tstring(t)
  if t == nil then
    return "nil"
  end
  local t2 = {}
  for k, v in pairs(t) do
    t2[k] = tostring(v)
  end
  local vals = table.concat(t2, ", ")
  return "[ " .. vals .. " ]"
end

-- Gets the length of a table (top-level only), for troubleshooting
function addon:tlen(t)
  if t == nil then return 0 end
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

-- Runs the provided function, catching any Lua errors and logging them to console
-- Currently only returns a single result
function addon:catch(fn, ...)
  local ok, result = pcall(fn, ...)
  if not(ok) then
    addon:error("Lua script error")
    if result then
      addon:error(result)
    end
  end
  return ok, result
end

function addon:pluralize(num, singular, plural)
  if num == 1 then
    return singular
  else
    -- If no plural is provided, you get lazy pluralization
    return plural or singular.."s"
  end
end

-- Returns only the event type of the current combat log event
function addon:GetClogEventType()
  local _, event = CombatLogGetCurrentEventInfo()
  return event
end

-- Returns the current combat log event info as a parsed object
-- Also adds some useful fields derived from this info
-- This object will be provided as the only parameter to functions
--   registered in PmqCombatLogEvents.lua
function addon:GetClog()
  local info = {CombatLogGetCurrentEventInfo()}
  local obj = {
    raw = info,
    timestamp = info[1],
    event = info[2],
    hideCaster = info[3],
    sourceGuid = info[4],
    sourceName = info[5],
    sourceFlags = info[6],
    sourceRaidFlags = info[7],
    destGuid = info[8],
    destName = info[9],
    destFlags = info[10],
    destRaidFlags = info[11]
  }

  -- Additional derived fields
  obj.sourceStr = obj.sourceName .. " (" .. obj.sourceGuid .. ")"
  obj.destStr = obj.destName .. " (" .. obj.destGuid .. ")"

  return obj
end

