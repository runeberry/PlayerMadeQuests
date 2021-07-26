local _, addon = ...

local condition = addon.QuestEngine:NewCondition("level")
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
  return addon:GetPlayerLevel() >= level
end