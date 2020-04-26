local _, addon = ...
addon:traceFile("AppEvents.lua")

addon.AppEvents = addon.Events:CreateBroker()