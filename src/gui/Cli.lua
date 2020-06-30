local _, addon = ...
local SlashCmdList, unpack = addon.G.SlashCmdList, addon.G.unpack

local handlers

SLASH_PMQ1 = "/pmq"
SlashCmdList.PMQ = function(msg)
  addon:catch(function()
    local args = addon:SplitWords(msg)
    if not args[1] then
      -- By default, show the Main Menu if no command is specified
      addon.MainMenu:Show()
      return
    end

    local cmd = (args[1]):lower()
    local handler = handlers[cmd]
    if not handler then
      addon.Logger:Warn("Unrecognized command:", cmd)
      return
    end

    table.remove(args, 1)
    handler(unpack(args))
  end)
end

handlers = {
  ["reset"] = function()
    addon.QuestLog:Clear()
    addon:PlaySound("QuestAbandoned")
  end,
  ["add"] = function(demoId)
    local ok, quest = addon.QuestDemos:CompileDemo(demoId)
    if not ok then
      addon.Logger:Error("Failed to add demo quest:", quest)
      return
    end
    addon.QuestLog:AddQuest(quest, addon.QuestStatus.Active)
    addon:PlaySound("QuestAccepted")
  end,
  ["log"] = function(logLevel)
    addon.PlayerSettings.MinLogLevel = addon:SetGlobalLogLevel(logLevel)
  end,
  ["show"] = function()
    addon:ShowQuestLog(true)
  end,
  ["hide"] = function()
    addon:ShowQuestLog(false)
  end,
  ["toggle"] = function()
    addon:ShowQuestLog(not(addon.PlayerSettings.IsQuestLogShown))
  end,
  ["dump"] = function(varname)
    local func = loadstring("return "..varname)
    setfenv(func, addon)
    local val = func()
    varname = "addon."..varname

    if type(val) == "table" then
      addon.Logger:Table(val)
      addon.Logger:Debug("^ Dumped table value for:", varname)
    else
      addon.Logger:Debug(varname..":", val)
    end
  end,
}