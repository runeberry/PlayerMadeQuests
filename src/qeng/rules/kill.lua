local _, addon = ...
addon:traceFile("rules/kill.lua")

local rule = addon.QuestEngine:NewRule("kill")

function rule:GetShortText(obj)
  if obj:HasCondition("target") then
    return "%t %p/%g"
  elseif obj.goal == 1 then
    return "Kill enemies %p/%g"
  end
end

function rule:BeforeCheckConditions(obj, cl)
  obj:SetMetadata("TargetUnitName", cl.destName)
  obj:SetMetadata("TargetUnitGuid", cl.destGuid)
end

function rule:AfterCheckConditions(obj)
  obj:SetMetadata("TargetUnitName", nil)
  obj:SetMetadata("TargetUnitGuid", nil)
end

addon:onload(function()
  addon.CombatLogEvents:Subscribe("PARTY_KILL", function(cl)
    addon.RuleEvents:Publish(rule.name, cl)
  end)
end)