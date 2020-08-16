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
      addon.Logger:Warn("Unrecognized command: %s", cmd)
      return
    end

    table.remove(args, 1)
    handler(unpack(args))
  end)
end

local function dumpToConsole(name, val)
  if type(val) == "table" then
    addon.Logger:Table(val)
    addon.Logger:Debug("^ Dumped table value for: %s", name)
  else
    addon.Logger:Debug("%s: %s", name, val)
  end
end

handlers = {
  ["reset"] = function()
    addon.QuestLog:DeleteAll()
    addon.QuestArchive:DeleteAll()
    addon:PlaySound("QuestAbandoned")
  end,
  ["add"] = function(demoId)
    local ok, quest = addon.QuestDemos:CompileDemo(demoId)
    if not ok then
      addon.Logger:Error("Failed to add demo quest: %s", quest)
      return
    end
    addon.QuestLog:SaveWithStatus(quest, addon.QuestStatus.Active)
    addon:PlaySound("QuestAccepted")
  end,
  ["log"] = function(name, level)
    addon:SetUserLogLevel(name, level)
  end,
  ["logstats"] = function()
    local stats = addon:GetLogStats()
    table.sort(stats, function(a, b) return a.name < b.name end)
    addon.Logger:Info("Logger stats:")
    for _, stat in pairs(stats) do
      addon.Logger:Info("    %s (%i printed, %i received @ %s)", stat.name, stat.stats.printed, stat.stats.received, stat.levelname)
    end
  end,
  ["show"] = function()
    addon.QuestLogFrame:ToggleShown(true)
  end,
  ["hide"] = function()
    addon.QuestLogFrame:ToggleShown(false)
  end,
  ["toggle"] = function()
    addon.QuestLogFrame:ToggleShown()
  end,
  ["dump"] = function(varname)
    local func = loadstring("return "..varname)
    setfenv(func, addon)
    local val = func()
    varname = "addon."..varname
    dumpToConsole(varname, val)
  end,
  ["dump-quest"] = function(nameOrId)
    local quest = addon.QuestLog:FindByID(nameOrId)
    if not quest then
      quest = addon.QuestLog:FindByQuery(function(q) return q.name == nameOrId end)
    end
    if not quest then
      addon.Logger:Warn("Quest not found: %s", nameOrId)
    else
      dumpToConsole(nameOrId, quest)
    end
  end,
  ["get"] = function(name)
    if not name then
      addon.Logger:Table(addon.PlayerSettings)
      return
    end

    addon.Logger:Info("Config value: %s = %s", name, tostring(addon.PlayerSettings[name]))
  end,
  ["set"] = function(name, value)
    if not name or not value then
      addon.Logger:Warn("/pmq set - name and value are required")
      return
    end

    addon.PlayerSettings[name] = addon:TryConvertString(value)
    addon.SaveData:Save("Settings", addon.PlayerSettings)
    addon.Logger:Info("Config value set: %s = %s", name, tostring(addon.PlayerSettings[name]))
  end,
  ["unset"] = function(name)
    if not name then
      addon.Logger:Warn("/pmq unset - name or \"all\" is required")
      return
    end

    if name == "all" then
      addon.PlayerSettings = {}
      addon.SaveData:Save("Settings", addon.PlayerSettings)
      addon.Logger:Info("All player settings have been cleared.")
      return
    end

    if addon.PlayerSettings[name] then
      addon.PlayerSettings[name] = nil
      addon.SaveData:Save("Settings", addon.PlayerSettings)
      addon.Logger:Info("Cleared setting: %s", name)
    end
  end,
  ["scan-events"] = function()
    addon.GameEvents:ToggleWatchAll()
  end,
  ["debug-quests"] = function()
    addon.MainMenu:Show()
    addon.MainMenu:ShowMenuScreen("DebugQuestListMenu")
  end,
  ["position"] = function()
    addon.PositionFinderFrame:ToggleShown()
  end,
}