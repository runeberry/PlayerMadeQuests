local _, addon = ...
addon:traceFile("RuleEvents.lua")

addon.RuleEvents = addon.Events:CreateBroker()