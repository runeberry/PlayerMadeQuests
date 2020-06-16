local _, addon = ...
addon:traceFile("PmqCli.lua")

local SlashCmdList = addon.G.SlashCmdList
local strsplit = addon.G.strsplit
local firstShow = true

SLASH_PMQ1 = "/pmq"

SlashCmdList.PMQ = function(msg, editbox)
  addon:catch(function()
    local args = { strsplit(" ", msg) }
    local cmd = (args[1] or ""):lower()

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
    elseif cmd == "dump" then
      local varname = args[2]
      local parts, sofar = { strsplit(".", varname) }
      local var
      for i, part in ipairs(parts) do
        if i == 1 then
          if part == "addon" then
            var = addon
          else
            var = _G[part]
          end
          sofar = part
        else
          if type(var) == "table" then
            var = var[part]
            sofar = sofar.."."..part
          else
            addon.Logger:Debug("Unable to index:", varname)
            varname = sofar
            break
          end
        end
      end

      if type(var) == "table" then
        addon.Logger:Table(var)
        addon.Logger:Debug("^ Dumped table value for:", varname)
      else
        addon.Logger:Debug(varname..":", var)
      end
    else
      if firstShow then
        -- Go to drafts on first open per session
        addon.MainMenu:NavToMenuScreen("drafts")
        firstShow = false
      else
        -- Otherwise simply show the main menu in the last state it was in
        addon.MainMenu:Show()
      end
    end
  end)
end