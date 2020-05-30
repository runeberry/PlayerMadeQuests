local _, addon = ...
local GetUnitName =addon.G.GetUnitName
local UnitGUID = addon.G.UnitGUID
addon:traceFile("conditions/target.lua")

local condition = addon.QuestEngine:NewCondition("target")
condition.allowMultiple = true

function condition:CheckCondition(obj, unitNames)
  -- The rule may want to override the default method for obtaining the targeted unit name
  local targetUnitName = obj:GetMetadata("TargetUnitName") or GetUnitName("target")

  if unitNames[targetUnitName] == nil then
    -- The targeted unit's name does not match the objective's unit name
    return false
  end

  if obj.goal == 1 then
    -- Only one unit to target, so the objective is satisfied
    return true
  end
  -- If the objective is to target multiples of the same NPC (i.e. 3 guards),
  -- make sure they're different by guid

  -- The rule may want to override the default method for obtaining the targeted unit guid
  local targetUnitGuid = obj:GetMetadata("TargetUnitGuid") or UnitGUID("target")

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
