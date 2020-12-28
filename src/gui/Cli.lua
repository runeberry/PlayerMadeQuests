local _, addon = ...
local SlashCmdList, unpack = addon.G.SlashCmdList, addon.G.unpack
local strjoin = addon.G.strjoin

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

local function tryRunScript(str)
  local func, err = loadstring(tostring(str))
  if not func then
    addon.Logger:Error("Error compiling script: %s", err)
    return false, err
  end

  setfenv(func, { addon = addon })

  local ret
  local ok, err2 = pcall(function()
    ret = { func() }
  end)
  if not ok then
    addon.Logger:Error("Error running script: %s", err2)
    return false, err2
  end

  return true, ret
end

handlers = {
  ["reset-quests"] = function()
    addon.QuestLog:DeleteAll()
    addon.QuestArchive:DeleteAll()
    addon:PlaySound("QuestAbandoned")
  end,
  ["log"] = function()
    addon.QuestLogFrame:ToggleShown()
  end,
  ["run"] = function(...)
    local script = strjoin(" ", ...)
    local ok, ret = tryRunScript(script)
    if not ok then return end

    if #ret > 0 then
      local stringed = {}
      for i, r in ipairs(ret) do
        stringed[i] = tostring(r)
      end
      ret = table.concat(stringed, ", ")
    else
      ret = "nil"
    end

    addon.Logger:Info("Script returned: %s", ret)
  end,
  ["dump"] = function(varname)
    local ok, ret = tryRunScript("return "..varname)
    if not ok then return end

    local val = ret[1]
    if type(val) == "table" then
      addon.Logger:Table(val)
      addon.Logger:Warn("^ Dumped table value for: %s", varname)
    else
      addon.Logger:Warn("%s: %s", varname, tostring(val))
    end
  end,
  ["dump-quest"] = function(nameOrId)
    local quest = addon.QuestLog:FindByID(nameOrId)
    if not quest then
      quest = addon.QuestLog:FindByQuery(function(q) return q.name == nameOrId end)
    end
    if not quest then
      addon.Logger:Warn("Quest not found: %s", nameOrId)
    else
      addon.Logger:Table(quest)
      addon.Logger:Warn("^ Dumped quest object: %s", tostring(nameOrId))
    end
  end,
  ["scan-events"] = function()
    addon.GameEvents:ToggleWatchAll()
  end,
  ["debug-quests"] = function()
    addon.MainMenu:Show()
    addon.MainMenu:ShowMenuScreen("DebugQuestListMenu")
  end,
  ["location"] = function()
    addon.LocationFinderFrame:ToggleShown()
  end,
  ["locations"] = function()
    addon.LocationFinderFrame:ToggleShown()
  end,
  ["emote"] = function()
    addon.EmoteFrame:ToggleShown()
  end,
  ["emotes"] = function()
    addon.EmoteFrame:ToggleShown()
  end,
  ["reset-config"] = function()
    addon.StaticPopups:Show("ResetAllConfig")
  end,
  ["update"] = function()
    addon:CheckForUpdates()
  end,
  ["lookup-item"] = function(...)
    local idOrName = strjoin(" ", ...)
    local item = addon:LookupItemSafe(idOrName)

    if item then
      addon.Logger:Warn("Item found: %s (%s)", tostring(item.link or item.name), tostring(item.id))
    else
      addon.Logger:Warn("No item found with id or name: %s", idOrName)
    end
  end,
}