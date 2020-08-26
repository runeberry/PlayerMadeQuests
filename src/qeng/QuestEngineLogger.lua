local _, addon = ...

addon.QuestEngineLogger = addon.Logger:NewLogger("Objectives")

local origLog = addon.QuestEngineLogger.Log
addon.QuestEngineLogger.Log = function(self, loglevel, str, ...)
  origLog(self, loglevel, "    "..tostring(str), ...)
end

function addon.QuestEngineLogger:Pass(str, ...)
  self:Debug(addon:Colorize("green", "[P] "..tostring(str)), ...)
end

function addon.QuestEngineLogger:Fail(str, ...)
  self:Debug(addon:Colorize("red", "[F] "..tostring(str)), ...)
end