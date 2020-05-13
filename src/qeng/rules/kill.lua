local _, addon = ...
addon:traceFile("rules/kill.lua")

local QuestEngine = addon.QuestEngine

local rule = QuestEngine:NewRule("kill")

function rule:GetDisplayText(obj)
  return obj:GetConditionDisplayText("target", "Kill enemies")
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