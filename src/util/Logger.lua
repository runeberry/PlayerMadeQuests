local _, addon = ...
local unpack, print = addon.G.unpack, addon.G.print

addon.Logger = nil -- Defined at the end of this file
addon.LogLevel = {
  silent = 0,
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
  [ll.silent] = "white",
  [ll.fatal] = "red",
  [ll.error] = "red",
  [ll.warn] = "yellow",
  [ll.info] = "white",
  [ll.debug] = "orange",
  [ll.trace] = "grey",
  [ll.none] = "grey"
}

local function newStatsTable()
  return {
    received = 0,
    printed = 0,
    level = {
      [ll.silent] = 0,
      [ll.fatal] = 0,
      [ll.error] = 0,
      [ll.warn] = 0,
      [ll.info] = 0,
      [ll.debug] = 0,
      [ll.trace] = 0,
      [ll.none] = 0
    }
  }
end

local globalStats = newStatsTable()

-- Enable this to bypass all logging rules and print everything to console
-- Only enable this if something is seriously broken with logging
local globalLogMode = addon.GLOBAL_LOG_MODE or lm.Pretty

-- Log levels below this level are always hidden unless debug-mode is enabled
local globalLogFilter = addon.GLOBAL_LOG_FILTER or ll.info

-- Buffer logs from all loggers until the app is loaded, then flush them
local useLogBuffer = true
local globalLogBuffer = {}

-- Each logger that's created will have its log level indexed by name here
local logLevels = {
  -- User-defined log levels will take precedence over system log levels
  user = {},
  system = {},
  initial = {}
}
-- Each logger will also be indexed by name so they can be tracked globally
local loggers = {}

-- For any given logger, the priority is:
-- User-defined level > system defined-level (defined by code) > initial level (defined when logger was created)
-- If there is a global log filter in place, no logs shall be printed below that level (unless overriden by a User-defined level)
-- By default, there is an info-level filter in place
local function getMinLogLevel(name)
  return logLevels.user[name] or math.min(globalLogFilter, (logLevels.system[name] or logLevels.initial[name] or ll.silent))
end

-- Returns the (number value) and (string name) of a given number or string representing a log level
local function getLogLevel(level)
  local value, name
  if type(level) == "string" then
    value = addon.LogLevel[level]
    name = level
  elseif type(level) == "number" then
    value = level
    for k, v in pairs(addon.LogLevel) do
      if v == value then
        name = k
        break
      end
    end
  end
  return value, name
end

addon:OnSaveDataLoaded(function()
  if addon.PlayerSettings.Logging then
    logLevels.user = addon:CopyTable(addon.PlayerSettings.Logging)
  end

  addon:SetGlobalLogFilter(addon.PlayerSettings["global-log-filter"])

  -- Flush all buffered logs
  -- print("Flushing log buffer:", #globalLogBuffer)
  useLogBuffer = false
  for _, l in pairs(globalLogBuffer) do
    l.logger:Log(l.loglevel, l.str, unpack(l.args))
  end
  globalLogBuffer = nil
  -- print("End flushing log buffer")
end)

local function bumpStats(statsTable, isPrinted, level)
  if isPrinted then
    statsTable.printed = statsTable.printed + 1
    globalStats.printed = globalStats.printed + 1
  end

  statsTable.received = statsTable.received + 1
  globalStats.received = globalStats.received + 1

  if level then
    statsTable.level[level] = statsTable.level[level] + 1
    globalStats.level[level] = statsTable.level[level] + 1
  end
end

local logMethods = {
  [lm.Pretty] = function(self, loglevel, str, ...)
    if useLogBuffer then
      table.insert(globalLogBuffer, { logger = self, loglevel = loglevel, str = str, args = { ... } })
      return
    end
    -- Log must be "higher priority" than both the instance and global log levels
    if loglevel <= getMinLogLevel(self.name) then
      print(addon:GetEscapeColor(logcolors[loglevel])..self.prefix, str, ...)
      bumpStats(self.stats, true, loglevel)
    else
      bumpStats(self.stats, false, loglevel)
    end
  end,
  [lm.Simple] = function(self, loglevel, str, ...)
    if useLogBuffer then
      table.insert(globalLogBuffer, { logger = self, loglevel = loglevel, str = str, args = { ... } })
      return
    end
    -- Log must be "higher priority" than both the instance and global log levels
    if loglevel <= getMinLogLevel(self.name) then
      print(self.prefix, str, ...)
      bumpStats(self.stats, true, loglevel)
    else
      bumpStats(self.stats, false, loglevel)
    end
  end,
  [lm.SimpleUnbuffered] = function(self, loglevel, str, ...)
    if loglevel <= getMinLogLevel(self.name) then
      print(self.prefix, str, ...)
      bumpStats(self.stats, true, loglevel)
    else
      bumpStats(self.stats, false, loglevel)
    end
  end
}

local methods = {
  -- This method is attached to the Logger and sets the "system" level of the logger (defined by code)
  ["SetLogLevel"] = function(self, loglevel)
    local value = getLogLevel(loglevel)
    if not value then return end
    logLevels.system[self.name] = value
  end,
  ["SetLogMode"] = function(self, logmode)
    self.Log = logMethods[logmode]
  end,
  ["Fatal"] = function(self, str, ...) self:Log(ll.fatal, str, ...) end,
  ["Error"] = function(self, str, ...) self:Log(ll.error, str, ...) end,
  ["Warn"] = function(self, str, ...) self:Log(ll.warn, str, ...) end,
  ["Info"] = function(self, str, ...) self:Log(ll.info, str, ...) end,
  ["Debug"] = function(self, str, ...) self:Log(ll.debug, str, ...) end,
  ["Trace"] = function(self, str, ...) self:Log(ll.trace, str, ...) end,
  ["Varargs"] = function(self, ...)
    local vals = {}
    for n=1, select('#', ...) do
      local val = select(n, ...)
      vals[#vals+1] = tostring(val)
    end
    self:Debug("Variadic args: [" .. table.concat(vals, ", ") .. "]")
  end,
  ["Table"] = function(self, t, key, indent, circ)
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
  end,
}

local function logger_NewLogger(self, name, min)
  if self then
    -- Inherit the logger name from the parent logger
    if name then
      name = self.name..":"..name
    else
      name = self.name
    end
    -- Inherit the log level unless another one was specified
    if not min then
      min = getMinLogLevel(name)
    end
  end

  local logger = {
    name = name,
    prefix = "["..name.."]",
    stats = newStatsTable(),

    NewLogger = logger_NewLogger,
    Log = logMethods[globalLogMode],
  }

  for fname, method in pairs(methods) do
    logger[fname] = method
  end

  if not min then
    min = ll.info
  end

  loggers[name] = logger
  logLevels.initial[name] = min

  return logger
end

-- Sets a user-defined minimum log level for a given logger
function addon:SetUserLogLevel(name, level)
  if not loggers[name] then
    addon.Logger:Warn(name, "is not a known logger.")
    return
  end

  local value = getLogLevel(level)
  if not value then
    addon.Logger:Warn(level, "is not a valid log level.");
    return
  end

  logLevels.user[name] = value

  if not addon.PlayerSettings.Logging then
    addon.PlayerSettings.Logging = {}
  end
  addon.PlayerSettings.Logging[name] = value
  addon.SaveData:Save("Settings", addon.PlayerSettings)
  addon.Logger:Info("Set log level for", name, "to", level..".")
end

function addon:GetLogStats()
  local stats = {}
  for name, logger in pairs(loggers) do
    local level, levelname = getLogLevel(getMinLogLevel(name))
    table.insert(stats, { name = name, level = level, levelname = levelname, stats = logger.stats })
  end
  local level, levelname = getLogLevel(globalLogFilter)
  table.insert(stats, { name = "*", level = level, levelname = levelname, stats = globalStats })
  return stats
end

function addon:SetGlobalLogFilter(level)
  level = getLogLevel(level)
  if level then
    globalLogFilter = level
    return level
  end
end

-- Cannot create the global logger until this method is available
addon.Logger = logger_NewLogger(nil, "PMQ", ll.trace)