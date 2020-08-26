local _, addon = ...
local logger = addon.QuestEngineLogger
local tokens = addon.QuestScriptTokens

addon:OnQuestEngineReady(function()
  addon.CombatLogEvents:Subscribe("PARTY_KILL", function(cl)
    addon.LastPartyKill = cl
    addon.QuestEvents:Publish(tokens.OBJ_KILL, cl)
  end)
end)