local _, addon = ...
local unpack = addon.G.unpack

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

-- Enable this to bypass all logging rules and print everything to console
local forceLogging = false
local minloglevel = nil
local loggers = {}

-- Buffer logs from all loggers until the app is loaded, then flush them
local useLogBuffer = true
local globalLogBuffer = {}

local logcolors = {
  [ll.fatal] = "red",
  [ll.error] = "red",
  [ll.warn] = "yellow",
  [ll.info] = "white",
  [ll.debug] = "orange",
  [ll.trace] = "grey",
  [ll.none] = "grey"
}

addon:OnSaveDataLoaded(function()
  minloglevel = addon.PlayerSettings.MinLogLevel or addon.LogLevel.info

  for _, logger in pairs(loggers) do
    -- Set minloglevel now that it's loaded from save file
    logger._minloglevel = logger._minloglevel or minloglevel
  end

  -- Flush all buffered logs
  -- print("Flushing log buffer")
  useLogBuffer = false
  for _, l in pairs(globalLogBuffer) do
    l.logger:log(l.loglevel, l.str, unpack(l.args))
  end
  globalLogBuffer = nil
  -- print("End flushing log buffer")
end)

local function logger_SetLogLevel(self, loglevel)
  self._minloglevel = loglevel
end

local function logger_log(self, loglevel, str, ...)
  if useLogBuffer then
    table.insert(globalLogBuffer, { logger = self, loglevel = loglevel, str = str, args = { ... } })
    return
  end
  if loglevel > self._minloglevel then
    return
  end
  print(addon:GetEscapeColor(logcolors[loglevel]).."[PMQ]", str, ...)
end

local function logger_forcelog(self, loglevel, str, ...)
  print("[PMQ]", str, ...)
end

-- Shorthand methods for logging
local function logger_fatal(self, str, ...) self:log(ll.fatal, str, ...) end
local function logger_error(self, str, ...) self:log(ll.error, str, ...) end
local function logger_warn(self, str, ...) self:log(ll.warn, str, ...) end
local function logger_info(self, str, ...) self:log(ll.info, str, ...) end
local function logger_debug(self, str, ...) self:log(ll.debug, str, ...) end
local function logger_trace(self, str, ...) self:log(ll.trace, str, ...) end

local function logger_varargs(self, ...)
  local vals = {}
  for n=1, select('#', ...) do
    local val = select(n, ...)
    vals[#vals+1] = tostring(val)
  end
  self:debug("Variadic args: [" .. table.concat(vals, ", ") .. "]")
end

local function logger_table(self, t, key, indent, circ)
  if t == nil then
    self:debug("Table is nil")
    return
  end
  indent = indent or ""
  circ = circ or {}
  circ[t] = true
  if key then
    self:debug(indent, key, "=", t, "(", addon:tlen(t), "elements )")
  else
    self:debug(t, "(", addon:tlen(t), "elements )")
  end
  indent = indent.."  "
  for k, v in pairs(t) do
    if type(v) == "table" then
      if circ[v] then
        self:debug(indent, k, "=", v, "(Dupe)")
      else
        self:table(v, k, indent, circ)
      end
    else
      self:debug(indent, k, "=", v)
    end
  end
end

function addon:NewLogger(min)
  local logger = {
    _logbuffer = {},
    _minloglevel = min or minloglevel,

    SetLogLevel = logger_SetLogLevel,

    log = logger_log,
    fatal = logger_fatal,
    error = logger_error,
    warn = logger_warn,
    info = logger_info,
    debug = logger_debug,
    trace = logger_trace,

    varargs = logger_varargs,
    table = logger_table
  }

  if forceLogging then
    logger.log = logger_forcelog
  end

  table.insert(loggers, logger)
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

  minloglevel = logvalue
  for _, logger in pairs(loggers) do
    -- set log level for any loggers that don't have one set explicitly
    logger._minloglevel = logger._minloglevel or minloglevel
  end
  print("[PMQ] Global log level set to:", logname)
  return minloglevel
end