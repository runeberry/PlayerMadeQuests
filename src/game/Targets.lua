local _, addon = ...
local SaveData = addon.SaveData

local saveDataField = "TargetGuidHistory"
local targetGuidHistory -- Set below, when save data is loaded

local function save()
  SaveData:Save(saveDataField, targetGuidHistory)
end

--- Checks the player's save data to determine if this target is excluded for
--- the provided context.
--- @param context string, the context to which this exclusion applies (usually objective id)
--- @param targetGuid string, the guid of the target to check
--- @return boolean, true if the target has been excluded, false otherwise
function addon:IsTargetExcluded(context, targetGuid)
  assert(type(context) == "string", "Failed to check IsTargetExcluded: context must be a string")
  assert(type(targetGuid) == "string", "Failed to check IsTargetExcluded: targetGuid must be a string")

  return targetGuidHistory[context] and targetGuidHistory[context][targetGuid]
end

--- Mark this target as "excluded" for the provided context - will cause
--- IsTargetExcluded to return true. Writes to save file.
--- @param context string, the context to which this exclusion applies (usually objective id)
--- @param targetGuid string, the guid of the target to exclude
--- @return boolean, true if the target was already excluded, false otherwise
function addon:AddTargetExclusion(context, targetGuid)
  assert(type(context) == "string", "Failed to AddTargetExclusion: context must be a string")
  assert(type(targetGuid) == "string", "Failed to AddTargetExclusion: targetGuid must be a string")

  local contextTGH = targetGuidHistory[context]
  if not contextTGH then
    contextTGH = {}
    targetGuidHistory[context] = contextTGH
  end

  if not contextTGH[targetGuid] then
    contextTGH[targetGuid] = true
    save()
    return false
  end

  return true
end

--- Clear all excluded targets for the provided context. Writes to save file.
--- @param context string, the context to which this exclusion applies (usually objective id)
function addon:ClearTargetExclusions(context)
  if type(context) ~= "string" then
    addon.Logger:Warn("Unable to ClearTargetExclusions: context must be a string (%s)", type(context))
    return
  end

  if targetGuidHistory[context] then
    targetGuidHistory[context] = nil
    save()
  end
end

--- Clear all excluded targets for all contexts. Writes to save file.
function addon:ClearAllTargetExclusions()
  SaveData:Clear(saveDataField)
end

--- Ensuring unique targets for objectives is a common pattern, so this
--- function was placed here to ensure it's handled consistently.
--- @param objective table - An objective template (for logger access)
--- @param obj table - The instance of the objective being evaluated
--- @param targetGuid string - The guid of the target
function addon:EvaluateUniqueTargetForObjective(objective, obj, targetGuid, allowDuplicatePlayerTargets)
  if not targetGuid then
    objective.logger:Fail("No unit is targeted")
    return false
  end

  if addon:IsTargetExcluded(obj.id, targetGuid) then
    -- Target has already been used for this objective, don't count it again
    objective.logger:Fail("Target has already been used for this objective")
    return false
  else
    objective.logger:Pass("Target is new for this objective")
    addon:AddTargetExclusion(obj.id, targetGuid)
    return true
  end
end

addon:OnBackendStart(function()
  targetGuidHistory = SaveData:LoadTable(saveDataField)

  -- Subscribe to events that should clean up the target history when appropriate
  addon.AppEvents:Subscribe("ObjectiveCompleted", function(obj)
    addon:ClearTargetExclusions(obj.id)
  end)
  addon.AppEvents:Subscribe("QuestDataReset", function()
    addon:ClearAllTargetExclusions()
  end)

  local function clearQuest(quest)
    for _, obj in ipairs(quest.objectives) do
      addon:ClearTargetExclusions(obj.id)
    end
  end

  addon.AppEvents:Subscribe("QuestStatusChanged", clearQuest)
  addon.AppEvents:Subscribe("QuestStarted", clearQuest)
end)
