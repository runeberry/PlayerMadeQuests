local _, addon = ...
addon:traceFile("AppEvents.lua")

addon.AppEvents = addon.Events:CreateBroker("AppEvent")
addon.AppEvents:SetLogLevel(addon.LogLevel.debug)
addon.AppEvents:EnableAsync()