local _, addon = ...
local unpack = addon.G.unpack

addon.Logger = nil -- Defined at the end of this file
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
addon.LogMode = {
  Pretty = "pretty",
  Simple = "simple",
  SimpleUnbuffered = "simple-unbuffered",
}
local lm = addon.LogMode

local logcolors = {
  [ll.fatal] = "red",
  [ll.error] = "red",
  [ll.warn] = "yellow",
  [ll.info] = "white",
  [ll.debug] = "orange",
  [ll.trace] = "grey",
  [ll.none] = "grey"
}

-- Enable this to bypass all logging rules and print everything to console
-- Only enable this if something is seriously broken with logging
local globalLogMode = addon.LOG_MODE or lm.Pretty

-- This will be updated from player settings when save data is loaded
local globalLogLevel = addon.LOG_LEVEL or ll.info

-- Buffer logs from all loggers until the app is loaded, then flush them
local useLogBuffer = true
local globalLogBuffer = {}

addon:OnSaveDataLoaded(function()
  globalLogLevel = addon.PlayerSettings.MinLogLevel or globalLogLevel

  -- Flush all buffered logs
  -- print("Flushing log buffer:", #globalLogBuffer)
  useLogBuffer = false
  for _, l in pairs(globalLogBuffer) do
    l.logger:Log(l.loglevel, l.str, unpack(l.args))
  end
  globalLogBuffer = nil
  -- print("End flushing log buffer")
end)

local function logger_SetLogLevel(self, loglevel)
  self._minloglevel = loglevel
end

local logMethods = {
  [lm.Pretty] = function(self, loglevel, str, ...)
    if useLogBuffer then
      table.insert(globalLogBuffer, { logger = self, loglevel = loglevel, str = str, args = { ... } })
      return
    end
    -- Log must be "higher priority" than both the instance and global log levels
    if loglevel <= globalLogLevel and loglevel <= self._minloglevel then
      print(addon:GetEscapeColor(logcolors[loglevel])..self._prefix, str, ...)
    end
  end,
  [lm.Simple] = function(self, loglevel, str, ...)
    if useLogBuffer then
      table.insert(globalLogBuffer, { logger = self, loglevel = loglevel, str = str, args = { ... } })
      return
    end
    -- Log must be "higher priority" than both the instance and global log levels
    if loglevel <= globalLogLevel and loglevel <= self._minloglevel then
      print(self._prefix, str, ...)
    end
  end,
  [lm.SimpleUnbuffered] = function(self, loglevel, str, ...)
    if loglevel <= globalLogLevel and loglevel <= self._minloglevel then
      print(self._prefix, str, ...)
    end
  end
}

-- Shorthand methods for logging
local function logger_Fatal(self, str, ...) self:Log(ll.fatal, str, ...) end
local function logger_Error(self, str, ...) self:Log(ll.error, str, ...) end
local function logger_Warn(self, str, ...) self:Log(ll.warn, str, ...) end
local function logger_Info(self, str, ...) self:Log(ll.info, str, ...) end
local function logger_Debug(self, str, ...) self:Log(ll.debug, str, ...) end
local function logger_Trace(self, str, ...) self:Log(ll.trace, str, ...) end

local function logger_Varargs(self, ...)
  local vals = {}
  for n=1, select('#', ...) do
    local val = select(n, ...)
    vals[#vals+1] = tostring(val)
  end
  self:Debug("Variadic args: [" .. table.concat(vals, ", ") .. "]")
end

local function logger_Table(self, t, key, indent, circ)
  if t == nil then
    self:Debug("Table is nil")
    return
  end
  indent = indent or ""
  circ = circ or {}
  circ[t] = true
  if key then
    self:Debug(indent, key, "=", t, "(", addon:tlen(t), "elements )")
  else
    self:Debug(t, "(", addon:tlen(t), "elements )")
  end
  indent = indent.."  "
  for k, v in pairs(t) do
    if type(v) == "table" then
      if circ[v] then
        self:Debug(indent, k, "=", v, "(Dupe)")
      else
        self:Table(v, k, indent, circ)
      end
    else
      self:Debug(indent, k, "=", v)
    end
  end
end

local function logger_NewLogger(self, name, min)
  if self then
    -- Inherit the logger name from the parent logger
    if name then
      name = self._name..":"..name
    else
      name = self._name
    end
    -- Inherit the log level unless another one was specified
    if not min then
      min = self._minloglevel
    end
  end

  local logger = {
    _name = name,
    _prefix = "["..name.."]",
    _minloglevel = min,

    NewLogger = logger_NewLogger,
    SetLogLevel = logger_SetLogLevel,

    Log = logMethods[globalLogMode],
    Fatal = logger_Fatal,
    Error = logger_Error,
    Warn = logger_Warn,
    Info = logger_Info,
    Debug = logger_Debug,
    Trace = logger_Trace,

    Varargs = logger_Varargs,
    Table = logger_Table
  }

  return logger
end

function addon:SetGlobalLogLevel(loglevel)
  local logname, logvalue

  if type(loglevel) == "string" then
    logname = loglevel
    logvalue = addon.LogLevel[logname]
  end

  if not logvalue then
    return
  end

  globalLogLevel = logvalue
  print("[PMQ] Global log level set to:", logname)
  return globalLogLevel
end

-- Cannot create the global logger until this method is available
addon.Logger = logger_NewLogger(nil, "PMQ", ll.trace)