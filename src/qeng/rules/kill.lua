local _, addon = ...
addon:traceFile("rules/kill.lua")

local rule = addon.QuestEngine:NewRule("kill")

function rule:GetDisplayText(obj)
  local str = ""
  if obj:HasCondition("target") then
    str = addon:GetConditionValueText(obj.conditions["target"])
  else
    str = "Kill enemies"
  end
  return str
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
  addon.CombatLogEvents:Subscribe("PARTY_KILL", function()
    addon.RuleEvents:Publish(rule.name, addon:GetClog())
  end)
end)