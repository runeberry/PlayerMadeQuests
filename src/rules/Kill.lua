local _, addon = ...
addon:traceFile("Kill.lua")

local rule = addon.QuestEngine:CreateRule("Kill")
rule.displayText = "Kill %1 %p/%g"

function rule:CheckObjective(obj)
  local unitName = GetUnitName("target")

  if obj.args[1] ~= unitName then
    -- The targeted unit's name does not match the objective's unit name
    return false
  end

  if obj.goal == 1 then
    -- Only one unit to talk to, so the objective is complete
    return true
  else
    -- If the objective is to talk to multiples of the same NPC (i.e. 3 guards),
    -- make sure they're different by guid
    local guid = UnitGUID("target")

    if obj.history == nil then
      -- First one, log this result and return true
      obj.history = { guid }
      return true
    end

    for _, g in pairs(obj.history) do
      if g == guid then
        -- Already talked to this NPC, don't count it
        return false
      end
    end

    -- Otherwise, log this guid and progress the objective
    table.insert(obj.history, guid)
    return true
  end
end

addon:onload(function()
  addon.CombatLogEvents:Subscribe("PARTY_KILL", function(cl)
    local unit = addon:ParseGUID(cl.destGuid)
    unit.name = cl.destName
    addon.RuleEvents:Publish(rule.name, unit)
  end)
end)