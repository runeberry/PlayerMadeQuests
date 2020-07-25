local _, addon = ...
local loader = addon.QuestScriptLoader
local tokens = addon.QuestScriptTokens
local GetUnitName, UnitGUID = addon.G.GetUnitName, addon.G.UnitGUID

local targetGuidHistory

-- If the objective is to target multiples of the same NPC (i.e. 3 guards),
-- make sure they're different by guid
local function isUniqueTargetGuid(obj, targetUnitGuid)
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
  addon.SaveData:Save("TargetGuidHistory", targetGuidHistory)
  return true
end

loader:AddScript(tokens.PARAM_TARGET, tokens.METHOD_EVAL, function(obj, unitNames)
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

loader:AddScript(tokens.PARAM_KILLTARGET, tokens.METHOD_EVAL, function(obj, unitNames)
  if not addon.LastPartyKill then return end

  local targetUnitName = addon.LastPartyKill.destName
  if unitNames[targetUnitName] == nil then
    -- The targeted unit's name does not match the objective's unit name
    return false
  end
  if obj.goal == 1 then
    -- Only one unit to target, so the objective is satisfied
    return true
  end
  return isUniqueTargetGuid(obj, addon.LastPartyKill.destGuid)
end)

addon:OnSaveDataLoaded(function()
  targetGuidHistory = addon.SaveData:LoadTable("TargetGuidHistory")

  -- Reset targetGuidHistory when appropriate
  addon.AppEvents:Subscribe("ObjectiveCompleted", function(obj)
    if obj.id and targetGuidHistory[obj.id] then
      targetGuidHistory[obj.id] = nil
      addon.SaveData:Save("TargetGuidHistory", targetGuidHistory)
    end
  end)
  addon.AppEvents:Subscribe("QuestDataReset", function()
    targetGuidHistory = {}
    addon.SaveData:Save("TargetGuidHistory", targetGuidHistory)
  end)
  addon.AppEvents:Subscribe("QuestStatusChanged", function(quest)
    for _, obj in ipairs(quest.objectives) do
      targetGuidHistory[obj.id] = nil
    end
    addon.SaveData:Save("TargetGuidHistory", targetGuidHistory)
  end)
end)