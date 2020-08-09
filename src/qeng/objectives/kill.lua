local _, addon = ...
local logger = addon.QuestEngine.ObjectiveLogger
local tokens = addon.QuestScriptTokens

addon:onload(function()
  addon.CombatLogEvents:Subscribe("PARTY_KILL", function(cl)
    addon.LastPartyKill = cl
    addon.QuestEvents:Publish(tokens.OBJ_KILL, cl)
  end)
end)