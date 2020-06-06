local _, addon = ...
addon:traceFile("rules/kill.lua")
local QuestEngine, tokens = addon.QuestEngine, addon.QuestScript.tokens

QuestEngine:AddScript(tokens.OBJ_KILL_SCRIPT, function(obj, cl)
  obj:SetMetadata("TargetUnitName", cl.destName)
  obj:SetMetadata("TargetUnitGuid", cl.destGuid)
end)

QuestEngine:AddScript(tokens.OBJ_KILL_POST_SCRIPT, function(obj)
  obj:SetMetadata("TargetUnitName", nil)
  obj:SetMetadata("TargetUnitGuid", nil)
end)

QuestEngine:AddScript(tokens.OBJ_KILL_TEXT, function(obj)
  return obj:GetConditionDisplayText("target", "Kill enemies")
end)

addon:onload(function()
  addon.CombatLogEvents:Subscribe("PARTY_KILL", function(cl)
    addon.QuestEvents:Publish(tokens.OBJ_KILL, cl)
  end)
end)