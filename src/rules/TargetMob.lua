local _, addon = ...
addon:traceFile("TargetMob.lua")

local rule = addon.QuestEngine:CreateRule("TargetMob")
rule.displayText = "Target %1 %p/%g"

function rule:CheckObjective(obj, unitName)
  -- Advance objective if targeted unit name matches objective's unitName
  return obj.args[1] == unitName
end

addon:onload(function()
  addon.GameEvents:Subscribe("PLAYER_TARGET_CHANGED", function()
    if UnitExists("target") then
      -- Advance objective if targeted unit name matches objective's unitName
      addon.RuleEvents:Publish(rule.name, GetUnitName("target", true))
    end
  end)
end)