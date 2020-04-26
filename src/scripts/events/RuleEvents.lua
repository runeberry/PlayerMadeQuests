local _, addon = ...
addon:traceFile("RuleEvents.lua")

addon.RuleEvents = addon.Events:CreateBroker()
addon.RuleEvents.logLevel = addon.LogLevel.debug