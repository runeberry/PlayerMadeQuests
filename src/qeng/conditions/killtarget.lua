local _, addon = ...
local logger = addon.QuestEngine.ObjectiveLogger
local loader = addon.QuestScriptLoader
local tokens = addon.QuestScriptTokens

loader:AddScript(tokens.PARAM_KILLTARGET, tokens.METHOD_PARSE, function(unitNames)
  local t = type(unitNames)
  assert(t == "string" or t == "table", t.." is not a valid type for "..tokens.PARAM_KILLTARGET)

  if t == "string" then
    unitNames = { unitNames }
  end

  return addon:DistinctSet(unitNames)
end)

loader:AddScript(tokens.PARAM_KILLTARGET, tokens.METHOD_EVAL, function(obj, unitNames)
  if not addon.LastPartyKill then return end

  local targetUnitName = addon.LastPartyKill.destName
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
  local isExcluded = addon:IsTargetExcluded(obj.id, addon.LastPartyKill.destGuid)
  if isExcluded then
    logger:Debug(logger.fail.."Target has already been used for this objective")
  else
    logger:Debug(logger.pass.."Target is new for this objective")
  end
  return not isExcluded
end)

loader:AddScript(tokens.PARAM_KILLTARGET, tokens.METHOD_POST_EVAL, function(obj, result, unitNames)
  if result then
    -- Objective was successful with this target, so exclude it from further progression
    addon:AddTargetExclusion(obj.id, addon.LastPartyKill.destGuid)
  end
end)