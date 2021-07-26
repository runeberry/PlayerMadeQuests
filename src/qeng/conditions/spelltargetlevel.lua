local _, addon = ...

local condition = addon.QuestEngine:NewCondition(addon.QuestScriptTokens.PARAM_SPELLTARGETLEVEL)
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
  local spellTargetName = addon.LastSpellCast.targetName
  if not spellTargetName then
    self.logger:Fail("No unit was targeted with the last spell")
    return false
  end

  local spellTargetLevel = addon:GetUnitLevelByName(spellTargetName)
  if not spellTargetLevel then
    self.logger:Fail("Spell target (%s) level not found", spellTargetName)
    return false
  end
  if spellTargetLevel < level then
    self.logger:Fail("Spell target (%s) level is too low (%i)", spellTargetName, spellTargetLevel)
    return false
  end

  self.logger:Pass("Spell target (%s) level is high enough (%i)", spellTargetName, spellTargetLevel)
  return true
end