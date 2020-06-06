local _, addon = ...
addon:traceFile("conditions/target.lua")
local QuestEngine, tokens = addon.QuestEngine, addon.QuestScript.tokens
local GetUnitName, UnitGUID = addon.G.GetUnitName, addon.G.UnitGUID

local function isUniqueTargetGuid(obj, targetUnitGuid)
  -- If the objective is to target multiples of the same NPC (i.e. 3 guards),
  -- make sure they're different by guid
  local targetGuidHistory = obj:GetMetadata("TargetGuidHistory")
  if not targetGuidHistory then
    targetGuidHistory = {}
    obj:SetMetadata("TargetGuidHistory", targetGuidHistory, true)
  end

  -- Get the targeting history for this specific objective
  local objTargetGuidHistory = targetGuidHistory[obj.id]
  if not objTargetGuidHistory then
    -- First one, log this result and return true
    objTargetGuidHistory = {}
    targetGuidHistory[obj.id] = objTargetGuidHistory
  end

  if objTargetGuidHistory[targetUnitGuid] then
    -- Already targeted this NPC for this objective, don't count it
    return false
  end

  -- Otherwise, log this guid and progress the objective
  objTargetGuidHistory[targetUnitGuid] = true
  return true
end

QuestEngine:AddScript(tokens.COND_TARGET_UNIT_SCRIPT, function(obj, unitNames)
  local targetUnitName = GetUnitName("target")
  if unitNames[targetUnitName] == nil then
    -- The targeted unit's name does not match the objective's unit name
    return false
  end
  if obj.goal == 1 then
    -- Only one unit to target, so the objective is satisfied
    return true
  end
  return isUniqueTargetGuid(obj, UnitGUID("target"))
end)

QuestEngine:AddScript(tokens.COND_TARGET_KILL_SCRIPT, function(obj, unitNames)
  local targetUnitName = obj:GetMetadata("TargetUnitName")
  if unitNames[targetUnitName] == nil then
    -- The targeted unit's name does not match the objective's unit name
    return false
  end
  if obj.goal == 1 then
    -- Only one unit to target, so the objective is satisfied
    return true
  end
  return isUniqueTargetGuid(obj, obj:GetMetadata("TargetUnitGuid"))
end)
