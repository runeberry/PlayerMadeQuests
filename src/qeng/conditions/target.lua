local _, addon = ...
local logger = addon.QuestEngine.ObjectiveLogger
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
    logger:Debug(logger.fail.."Target has already been used for this objective (%s)", targetUnitGuid)
    return false
  end

  -- Otherwise, log this guid and progress the objective
  objTargetGuidHistory[targetUnitGuid] = true
  addon.SaveData:Save("TargetGuidHistory", targetGuidHistory)
  logger:Debug(logger.pass.."New target for objective (%s)", targetUnitGuid)
  return true
end

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
    logger:Debug(logger.fail.."Target name does not match (%s)", targetUnitName)
    return false
  end
  if obj.goal == 1 then
    -- Only one unit to target, so the objective is satisfied
    logger:Debug(logger.pass.."Target name match, and goal is 1 (%s)", targetUnitName)
    return true
  end
  return isUniqueTargetGuid(obj, UnitGUID("target"))
end)

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
    logger:Debug(logger.fail.."Target name does not match (%s)", targetUnitName)
    return false
  end
  if obj.goal == 1 then
    -- Only one unit to target, so the objective is satisfied
    logger:Debug(logger.pass.."Target name match, and goal is 1 (%s)", targetUnitName)
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