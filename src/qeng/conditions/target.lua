local _, addon = ...
local logger = addon.QuestEngine.ObjectiveLogger
local loader = addon.QuestScriptLoader
local tokens = addon.QuestScriptTokens
local GetUnitName, UnitGUID = addon.G.GetUnitName, addon.G.UnitGUID

loader:AddScript(tokens.PARAM_TARGET, tokens.METHOD_PARSE, function(unitNames)
  local t = type(unitNames)
  assert(t == "string" or t == "table", t.." is not a valid type for "..tokens.PARAM_TARGET)

  if t == "string" then
    unitNames = { unitNames }
  end

  return addon:DistinctSet(unitNames)
end)

loader:AddScript(tokens.PARAM_TARGET, tokens.METHOD_EVAL, function(obj, unitNames)
  local targetUnitName = GetUnitName("target")
  if not targetUnitName then
    -- No unit is targeted
    logger:Debug(logger.fail.."No unit is targeted")
    return false
  end
  if unitNames[targetUnitName] == nil then
    -- The targeted unit's name does not match the objective's unit name
    logger:Debug(logger.fail.."Target name does not match")
    return false
  end
  if obj.goal == 1 then
    -- Only one unit to target, so the objective is satisfied
    logger:Debug(logger.pass.."Target name match, and goal is 1")
    return true
  end
  local isExcluded = addon:IsTargetExcluded(obj.id, UnitGUID("target"))
  if isExcluded then
    logger:Debug(logger.fail.."Target has already been used for this objective")
  else
    logger:Debug(logger.pass.."Target is new for this objective")
  end
  return not isExcluded
end)

loader:AddScript(tokens.PARAM_TARGET, tokens.METHOD_POST_EVAL, function(obj, result, unitNames)
  if result then
    -- Objective was successful with this target, so exclude it from further progression
    addon:AddTargetExclusion(obj.id, UnitGUID("target"))
  end
end)
