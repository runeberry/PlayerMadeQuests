local _, addon = ...

addon.Ace = LibStub("AceAddon-3.0"):NewAddon("PlayerMadeQuests", "AceEvent-3.0", "AceSerializer-3.0", "AceTimer-3.0")
addon.AceGUI = LibStub("AceGUI-3.0")
addon.LibCompress = LibStub("LibCompress")

local savedSettings

function addon.Ace:OnInitialize()
  local ok, msg = addon:catch(function()
    addon.SaveData:Init()

    addon:load()

    savedSettings = addon.SaveData:LoadTable("Settings")

    if savedSettings.MinLogLevel ~= nil then
      addon.MinLogLevel = savedSettings.MinLogLevel
    end

    addon._loaded = true
    addon:flushLogs()

    addon.GameEvents:Start()
    addon.CombatLogEvents:Start()

    addon.GameEvents:Subscribe("PLAYER_ENTERING_WORLD", function()
      if savedSettings.IsDemoFrameShown then
        addon:ShowDemoFrame()
      end

      if savedSettings.IsQuestLogShown then
        addon:ShowQuestLog(true)
      end
    end)

    addon:info("PMQ Loaded")
  end)
  if not ok then
    print("[PMQ] Fatal error on startup:", msg)
  end
end

function addon.Ace:OnEnable()

end

function addon.Ace:OnDisable()

end

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
addon._logBuffer = {}

-- Prints a message to console with respect to MinLogLevel
function addon:log(loglevel, str, ...)
  if addon._loaded == nil then
    table.insert(addon._logBuffer, { loglevel = loglevel, str = str, args = { ... } })
    return
  end
  if loglevel > addon.MinLogLevel then
    return
  end
  print("[PMQ]", str, ...)
end

function addon:flushLogs()
  for _, log in pairs(addon._logBuffer) do
    addon:log(log.loglevel, log.str, unpack(log.args))
  end
  addon._logBuffer = {}
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
  addon:trace("[PMQ] File loaded:", filename)
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

function addon:logtable(t, key, indent, circ)
  indent = indent or ""
  circ = circ or {}
  circ[t] = true
  if key then
    addon:info(indent, key, "=", t, "(", self:tlen(t), "elements )")
  else
    addon:info(t, "(", self:tlen(t), "elements )")
  end
  indent = indent.."  "
  for k, v in pairs(t) do
    if type(v) == "table" then
      if circ[v] then
        addon:info(indent, k, "=", v, "(Dupe)")
      else
        self:logtable(v, k, indent, circ)
      end
    else
      addon:info(indent, k, "=", v)
    end
  end
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

-- Defer code execution until the addon is fully loaded
local _onloadBuffer = {}
function addon:onload(fn)
  table.insert(_onloadBuffer, fn)
end

function addon:load()
  if _onloadBuffer == nil then return end
  for _, fn in pairs(_onloadBuffer) do
    addon:catch(fn)
  end
  _onloadBuffer = nil
end

function addon:OnSaveDataLoaded(fn)
  addon.AppEvents:Subscribe("SaveDataLoaded", fn)
end

-- Adapted from the CSV parser found here: http://lua-users.org/wiki/LuaCsv
function addon:strWords(line)
  local res = {}
  local pos = 1
  local sep = " "
  while true do
    local c = string.sub(line,pos,pos)
    if (c == "") then break end
    if (c == '"') then
      -- quoted value (ignore separator within)
      local txt = ""
      repeat
        local startp,endp = string.find(line,'^%b""',pos)
        txt = txt..string.sub(line,startp+1,endp-1)
        pos = endp + 1
        c = string.sub(line,pos,pos)
        if (c == '"') then txt = txt..'"' end
        -- check first char AFTER quoted string, if it is another
        -- quoted string without separator, then append it
        -- this is the way to "escape" the quote char in a quote. example:
        --   value1,"blub""blip""boing",value3  will result in blub"blip"boing  for the middle
      until (c ~= '"')
      table.insert(res,txt)
      assert(c == sep or c == "")
      pos = pos + 1
    elseif (c == "'") then -- jb: this parser supports single and double quotes
      -- quoted value (ignore separator within)
      local txt = ""
      repeat
        local startp,endp = string.find(line,"^%b''",pos)
        txt = txt..string.sub(line,startp+1,endp-1)
        pos = endp + 1
        c = string.sub(line,pos,pos)
        if (c == "'") then txt = txt.."'" end
        -- check first char AFTER quoted string, if it is another
        -- quoted string without separator, then append it
        -- this is the way to "escape" the quote char in a quote. example:
        --   value1,"blub""blip""boing",value3  will result in blub"blip"boing  for the middle
      until (c ~= "'")
      table.insert(res,txt)
      assert(c == sep or c == "")
      pos = pos + 1
    else
      -- no quotes used, just look for the first separator
      local startp,endp = string.find(line,sep,pos)
      if (startp) then
        table.insert(res,string.sub(line,pos,startp-1))
        pos = endp + 1
      else
        -- no separator found -> use rest of string and terminate
        table.insert(res,string.sub(line,pos))
        break
      end
    end
  end
  return res
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

-- Parses a GUID string into a table with named properties
-- Parsed based on this information: https://wow.gamepedia.com/GUID
function addon:ParseGUID(guid)
  local parsed = {
    GUID = guid
  }

  local parts = strsplit("-", parsed.GUID)
  local numParts = addon:tlen(parts)

  if numParts == 3 then
    -- unit is another player
    parsed.type = parts[1]
    parsed.serverID = parts[2]
    parsed.UID = parts[3]
  elseif numParts == 4 then
    -- unit is an item (does not contain any helpful identification)
    parsed.type = parts[1]
    parsed.serverID = parts[2]
    parsed.UID = parts[4]
  elseif numParts == 7 then
    -- unit is a creature, pet, object, or vehicle
    parsed.type = parts[1]
    parsed.serverID = parts[3]
    parsed.instanceID = parts[4]
    parsed.zoneUID = parts[5]
    parsed.ID = parts[6]
    parsed.spawnUID = parts[7]
  else
    error("Unrecognized GUID format: "..parsed.GUID)
  end

  return parsed
end

local idCounter = 0
-- Returns a string ID based on an incrementing counter and the current time
function addon:CreateID(str)
  idCounter = idCounter + 1
  local id = idCounter.."-"..time()
  if str then
    id = string.gsub(str, "%%i", id)
  end
  return id
end

-- Removes all fields that are not of type: string, number, boolean, or table
-- Removes all fields that begin with _
-- May not play well with array tables... idk!
function addon:CleanTable(t, circ)
  circ = circ or {}
  circ[t] = true -- Ensure the provided table won't get cleaned twice
  local ktype, vtype
  for k, v in pairs(t) do
    ktype = type(k)
    vtype = type(v)
    if ktype == "string" and k:match("^_") then
      -- Remove the value
      t[k] = nil
    elseif vtype == "table" then
      if not circ[v] then
        self:CleanTable(v, circ)
      end
    elseif vtype == "string" or vtype == "number" or vtype == "boolean" then
      -- Leave the value alone
    else
      -- Remove the value
      t[k] = nil
    end
  end
end

-- Performs a deep copy of the table and all subtables
-- References to functions will not be changed
function addon:CopyTable(t, circ)
  circ = circ or {}
  local copy = {}
  circ[t] = copy -- Ensure the provided table won't get copied twice
  for k, v in pairs(t) do
    if type(v) == "table" then
      if circ[v] then
        -- Use the same copy for each instance of the same inner table
        copy[k] = circ[v]
      else
        copy[k] = self:CopyTable(v, circ)
      end
    else
      copy[k] = v
    end
  end
  return copy
end

-- Performs a recursive table merge of t2 onto t1
-- If any fields collide, t2 will overwrite t1
-- Returns a new table - does not modify t1 or t2
function addon:MergeTable(t1, t2, circ)
  local merged = self:CopyTable(t1)
  circ = circ or {}
  circ[t1] = merged -- Ensure that both provided tables will only be merged once
  circ[t2] = merged
  circ[merged] = merged -- Ensure that any references to the merged table are not re-merged
  for k, v in pairs(t2) do
    if type(v) == "table" then
      if circ[v] then
        merged[k] = circ[v]
      elseif type(merged[k]) == "table" then
        -- If t1 and t2 both have tables at index k,
        -- then merge the two subtables and assign the result
        merged[k] = self:MergeTable(merged[k], v, circ)
      else
        -- Otherwise, t2's subtable simply overwrites t1's value
        merged[k] = self:CopyTable(v, circ)
      end
    else
      merged[k] = v
    end
  end
  return merged
end