local _, addon = ...

local condition = addon.QuestEngine:NewCondition(addon.QuestScriptTokens.PARAM_TARGETLEVEL)
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
  local targetLevel = addon:GetUnitLevel("target")

  if not targetLevel then
    self.logger:Fail("Target level not found")
    return false
  end
  if targetLevel < level then
    self.logger:Fail("Target level is too low (%i)", targetLevel)
    return false
  end

  self.logger:Pass("Target level is high enough (%i)", targetLevel)
  return true
end