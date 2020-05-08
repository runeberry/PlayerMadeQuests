local _, addon = ...
addon:traceFile("RuleEvents.lua")

addon.RuleEvents = addon.Events:CreateBroker("RuleEvent")
addon.RuleEvents.logLevelPublish = addon.LogLevel.trace
addon.RuleEvents.logLevelHandle = addon.LogLevel.debug