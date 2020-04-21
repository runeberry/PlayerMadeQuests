local _, addon = ...
addon:traceFile("PmqCli.lua")

SLASH_PMQ1 = "/pmq"

SlashCmdList.PMQ = function(msg, editbox)
  addon:catch(function()
    local args = { strsplit(" ", msg) }
    local numargs = addon:tlen(args)

    if args[1] == "reset" then
      addon.qlog:Reset()
    elseif args[1] == "add" then
      addon.qlog:AddQuest(args[2])
    elseif args[1] == "list" then
      addon.qlog:PrintQuests()
    elseif args[1] == "log" then
      addon.MinLogLevel = tonumber(args[2])
      addon:fatal("Log level set to", args[2])
    else
      addon:info("PMQ Version 0.0.1")
    end
  end)
end