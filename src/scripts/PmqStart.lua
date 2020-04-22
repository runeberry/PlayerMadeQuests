local _, addon = ...
addon:traceFile("PmqStart.lua")

addon.events:addOnLoadHandler(function()
  addon:info("PMQ Loaded")
end)