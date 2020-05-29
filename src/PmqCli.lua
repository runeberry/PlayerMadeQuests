local _, addon = ...
addon:traceFile("PmqCli.lua")

local SlashCmdList = addon.G.SlashCmdList
local strsplit = addon.G.strsplit

SLASH_PMQ1 = "/pmq"

SlashCmdList.PMQ = function(msg, editbox)
  addon:catch(function()
    local args = { strsplit(" ", msg) }
    local cmd = args[1]

    if cmd == "reset" then
      addon.QuestLog:Clear()
    elseif cmd == "add" then
      local ok, quest = addon.QuestDemos:CompileDemo(args[2])
      if not ok then
        addon.Logger:Error("Failed to add demo quest:", quest)
        return
      end
      addon.QuestLog:AcceptQuest(quest)
    elseif cmd == "log" then
      addon.PlayerSettings.MinLogLevel = addon:SetGlobalLogLevel(args[2])
    elseif cmd == "show" then
      addon:ShowQuestLog(true)
    elseif cmd == "hide" then
      addon:ShowQuestLog(false)
    elseif cmd == "toggle" then
      addon:ShowQuestLog(not(addon.PlayerSettings.IsQuestLogShown))
    elseif cmd == "print" then
      addon.QuestLog:Print()
    else
      addon.MainMenu:Show("drafts")
    end
  end)
end