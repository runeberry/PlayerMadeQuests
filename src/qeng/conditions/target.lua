local _, addon = ...
local GetUnitName = GetUnitName
local UnitGUID = UnitGUID
addon:traceFile("conditions/target.lua")

local condition = addon.QuestEngine:NewCondition("target")
condition.allowMultiple = true

function condition:CheckCondition(obj, unitNames)
  -- todo: Build objective metadata
  local targetUnitName
  if obj.metadata.targetUnitName then
    -- The rule wants to override the default method for obtaining the targeted unit name
    targetUnitName = obj.metadata.targetUnitName
    obj.metadata.targetUnitName = nil -- No other conditions should need this, erase it for safety
  else
    -- Otherwise, get the name of the currently targeted unit
    targetUnitName = GetUnitName("target")
  end

  if unitNames[targetUnitName] == nil then
    -- The targeted unit's name does not match the objective's unit name
    return false
  end

  if obj.goal == 1 then
    -- Only one unit to target, so the objective is satisfied
    return true
  else
    -- If the objective is to target multiples of the same NPC (i.e. 3 guards),
    -- make sure they're different by guid

    local targetUnitGuid
    if obj.metadata.targetUnitGuid then
      -- The rule wants to override the default method for obtaining the targeted unit guid
      targetUnitGuid = obj.metadata.targetUnitGuid
      obj.metadata.targetUnitGuid = nil -- No other conditions should need this, erase it for safety
    else
      -- Otherwise, get the name of the currently targeted unit
      targetUnitGuid = UnitGUID("target")
    end

    if obj.metadata.targetGuidHistory == nil then
      obj.metadata.targetGuidHistory = {}
    end

    local guidHistory = obj.metadata.targetGuidHistory[obj.id]
    if guidHistory == nil then
      -- First one, log this result and return true
      obj.metadata.targetGuidHistory[obj.id] = { targetUnitGuid }
      return true
    end

    for _, g in pairs(guidHistory) do
      if g == targetUnitGuid then
        -- Already targeted this NPC for this objective, don't count it
        return false
      end
    end

    -- Otherwise, log this guid and progress the objective
    table.insert(guidHistory, targetUnitGuid)
    return true
  end
end
