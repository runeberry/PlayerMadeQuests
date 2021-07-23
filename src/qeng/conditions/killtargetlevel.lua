local _, addon = ...

local condition = addon.QuestEngine:NewCondition(addon.QuestScriptTokens.PARAM_KILLTARGETLEVEL)
condition:AllowType("number")

-- Add 3 levels to cap to account for elite mobs
local maxLevel = addon.WOW_LEVEL_CAP + 3

function condition:OnValidate(rawValue, options)
  if rawValue < 1 or rawValue > maxLevel then
    return false, string.format("Level must be in range 1-%i", maxLevel)
  end
  return true
end

function condition:Evaluate(level)
  local killTargetName = addon.LastPartyKill.destName
  local killTargetLevel = addon:GetUnitLevelByName(killTargetName)

  if not killTargetLevel then
    self.logger:Fail("Kill target (%s) level not found", killTargetName)
    return false
  end
  if killTargetLevel < level then
    self.logger:Fail("Kill target (%s) level is too low (%i)", killTargetName, killTargetLevel)
    return false
  end

  self.logger:Pass("Kill target (%s) level is high enough (%i)", killTargetName, killTargetLevel)
  return true
end