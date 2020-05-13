local _, addon = ...
addon:traceFile("PmqCli.lua")

local SlashCmdList = addon.G.SlashCmdList
local strsplit = addon.G.strsplit

local logger = addon:NewLogger()

SLASH_PMQ1 = "/pmq"

SlashCmdList.PMQ = function(msg, editbox)
  addon:catch(function()
    local args = { strsplit(" ", msg) }
    local cmd = args[1]

    if cmd == "reset" then
      addon.QuestEngine:ResetQuestLog()
      logger:info("Quest log reset")
    elseif cmd == "add" then
      local demo = addon.QuestDemos:GetDemoByID(args[2])
      if not demo then
        logger:error("Error: no demo quest exists with id:", args[2])
        return
      end
      local parameters = addon.QuestEngine:Compile(demo.script)
      local quest = addon.QuestEngine:NewQuest(parameters)
      quest:StartTracking()
      addon.QuestEngine:Save()
      logger:info("Accepted quest -", quest.name)
    elseif cmd == "log" then
      addon.PlayerSettings.MinLogLevel = addon:SetGlobalLogLevel(args[2])
    elseif cmd == "show" then
      addon:ShowQuestLog(true)
    elseif cmd == "hide" then
      addon:ShowQuestLog(false)
    elseif cmd == "toggle" then
      addon:ShowQuestLog(not(addon.PlayerSettings.IsQuestLogShown))
    elseif cmd == "demoframe" then
      addon:ShowDemoFrame()
    elseif cmd == "list" then
      addon.QuestEngine:PrintQuestLog()
    else
      addon.MainMenu:Show()
    end
  end)
end