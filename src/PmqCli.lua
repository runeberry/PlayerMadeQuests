local _, addon = ...
local savedSettings
addon:traceFile("PmqCli.lua")

SLASH_PMQ1 = "/pmq"

SlashCmdList.PMQ = function(msg, editbox)
  addon:catch(function()
    local args = { strsplit(" ", msg) }
    local cmd = args[1]

    if cmd == "reset" then
      addon.QuestLog:Reset()
    elseif cmd == "add" then
      local demo = addon.QuestDemos:FindByID(args[2])
      if not demo then
        addon:error("Error: no demo quest exists with id:", args[2])
        return
      end
      addon.QuestLog:AcceptFromDemo(demo)
    elseif cmd == "log" then
      addon.MinLogLevel = tonumber(args[2])
      savedSettings.MinLogLevel = addon.MinLogLevel
      addon:fatal("Log level set to", args[2])
    elseif cmd == "show" then
      addon:ShowQuestLog(true)
    elseif cmd == "hide" then
      addon:ShowQuestLog(false)
    elseif cmd == "toggle" then
      addon:ShowQuestLog(not(savedSettings.IsQuestLogShown))
    elseif cmd == "demoframe" then
      addon:ShowDemoFrame()
    elseif cmd == "list" then
      addon.QuestLog:Print()
    else
      addon:info("PMQ Version 0.0.1")
    end
  end)
end

addon:onload(function()
  savedSettings = addon.SaveData:LoadTable("Settings")
end)