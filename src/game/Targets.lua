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

function addon:targets()
  return targetGuidHistory
end

addon:OnSaveDataLoaded(function()
  targetGuidHistory = SaveData:LoadTable(saveDataField)

  -- Subscribe to events that should clean up the target history when appropriate
  addon.AppEvents:Subscribe("ObjectiveCompleted", function(obj)
    addon:ClearTargetExclusions(obj.id)
  end)
  addon.AppEvents:Subscribe("QuestDataReset", function()
    addon:ClearAllTargetExclusions()
  end)
  addon.AppEvents:Subscribe("QuestStatusChanged", function(quest)
    for _, obj in ipairs(quest.objectives) do
      addon:ClearTargetExclusions(obj.id)
    end
  end)
end)
