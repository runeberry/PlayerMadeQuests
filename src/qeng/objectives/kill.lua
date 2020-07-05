local _, addon = ...
addon:traceFile("objectives/kill.lua")
local compiler, tokens = addon.QuestScriptCompiler, addon.QuestScript.tokens

addon:onload(function()
  addon.CombatLogEvents:Subscribe("PARTY_KILL", function(cl)
    addon.LastPartyKill = cl
    addon.QuestEvents:Publish(tokens.OBJ_KILL, cl)
  end)
end)