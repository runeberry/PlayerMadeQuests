local _, addon = ...
addon:traceFile("QuestEvents.lua")

addon.QuestEvents = addon.Events:CreateBroker("QuestEvent")
addon.QuestEvents:SetLogLevel(addon.LogLevel.info)