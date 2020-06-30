local _, addon = ...
addon:traceFile("objectives/kill.lua")
local compiler, tokens = addon.QuestScriptCompiler, addon.QuestScript.tokens

compiler:AddScript(tokens.OBJ_KILL, tokens.METHOD_PRE_COND, function(obj, cl)
  obj:SetMetadata("TargetUnitName", cl.destName)
  obj:SetMetadata("TargetUnitGuid", cl.destGuid)
end)

compiler:AddScript(tokens.OBJ_KILL, tokens.METHOD_POST_COND, function(obj)
  obj:SetMetadata("TargetUnitName", nil)
  obj:SetMetadata("TargetUnitGuid", nil)
end)

addon:onload(function()
  addon.CombatLogEvents:Subscribe("PARTY_KILL", function(cl)
    addon.QuestEvents:Publish(tokens.OBJ_KILL, cl)
  end)
end)