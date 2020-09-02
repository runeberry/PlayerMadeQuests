local _, addon = ...
local GetUnitName, UnitGUID = addon.G.GetUnitName, addon.G.UnitGUID

local condition = addon.QuestEngine:NewCondition(addon.QuestScriptTokens.PARAM_TARGET)
condition:AllowType("string")
condition:AllowMultiple(true)

function condition:OnParse(arg)
  if type(arg) == "string" then
    arg = { arg }
  end
  return addon:DistinctSet(arg)
end

function condition:Evaluate(unitNames, cp)
  local targetUnitName = GetUnitName("target")
  if not targetUnitName then
    -- No unit is targeted
    self.logger:Fail("No unit is targeted")
    return false
  end
  if unitNames[targetUnitName] == nil then
    -- The targeted unit's name does not match the objective's unit name
    self.logger:Fail("Target name does not match")
    return false
  end
  if cp.goal == 1 then
    -- Only one unit to target, so the objective is satisfied
    self.logger:Pass("Target name match, and goal is 1")
    return true
  end
  local isExcluded = addon:IsTargetExcluded(cp.id, UnitGUID("target"))
  if isExcluded then
    self.logger:Fail("Target has already been used for this objective")
  else
    self.logger:Pass("Target is new for this objective")
  end
  return not isExcluded
end

function condition:AfterEvaluate(result, unitNames, cp)
  if result then
    -- Objective was successful with this target, so exclude it from further progression
    addon:AddTargetExclusion(cp.id, UnitGUID("target"))
  end
end
