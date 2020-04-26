local _, addon = ...
addon:traceFile("KillMob.lua")

local rule = addon.QuestEngine:CreateRule("KillMob")
rule.displayText = "Kill %1 %p/%g"

function rule:CheckObjective(obj, unitName)
  -- Advance objective if killed unit name matches objective's unitName
  return obj.args[1] == unitName
end

addon.CombatLogEvents:Subscribe("PARTY_KILL", function(cl)
  addon.RuleEvents:Publish(rule.name, cl.destName)
end)