local _, addon = ...
addon:traceFile("PmqCli.lua")

SLASH_PMQ1 = "/pmq"

SlashCmdList.PMQ = function(msg, editbox)
  addon:catch(function()
    local args = { strsplit(" ", msg) }
    local cmd = args[1]

    if cmd == "reset" then
      addon.qlog:Reset()
      PlayerMadeQuestsCache = {}
      PlayerMadeQuestsGlobalCache = {}
      addon:info("Cache reset")
    elseif cmd == "add" then
      addon.qlog:AddQuest(args[2])
    elseif cmd == "list" then
      addon.qlog:PrintQuests()
    elseif cmd == "log" then
      addon.MinLogLevel = tonumber(args[2])
      addon:fatal("Log level set to", args[2])
    elseif cmd == "show" then
      addon:ShowQuestLog(true)
    elseif cmd == "hide" then
      addon:ShowQuestLog(false)
    elseif cmd == "toggle" then
      addon:ShowQuestLog(not(PlayerMadeQuestsCache.IsQuestLogShown))
    elseif cmd == "demoframe" then
      addon:ShowDemoFrame()
    else
      addon:info("PMQ Version 0.0.1")
    end
  end)
end