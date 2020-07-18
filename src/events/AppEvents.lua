local _, addon = ...
addon:traceFile("AppEvents.lua")
addon.AppEvents = addon.Events:CreateBroker("AppEvent")
addon.AppEvents:EnableAsync()