local _, addon = ...

addon.QuestEngineLogger = addon.Logger:NewLogger("QuestEngine", addon.LogLevel.info)

local passPrefix = "[P] "
local failPrefix = "[F] "

function addon.QuestEngineLogger:Pass(str, ...)
  self:Debug(passPrefix..tostring(str), ...)
end

function addon.QuestEngineLogger:Fail(str, ...)
  self:Debug(failPrefix..tostring(str), ...)
end

addon:OnConfigLoaded(function()
  passPrefix = addon:Colorize("green", passPrefix)
  failPrefix = addon:Colorize("red", failPrefix)
end)