local _, addon = ...

local condition = addon.QuestEngine:NewCondition(addon.QuestScriptTokens.PARAM_SPELLTARGETFACTION)
condition:AllowType("string")
condition:AllowValues(addon.WOW_FACTIONS)

function condition:Evaluate(faction)
  local spellTargetName = addon.LastSpellCast.targetName
  if not spellTargetName then
    self.logger:Fail("No unit was targeted with the last spell")
    return false
  end

  local spellTargetFaction = addon:GetUnitFactionByName(spellTargetName)
  if not spellTargetFaction then
    self.logger:Fail("Spell target (%s) has no faction", spellTargetName)
    return false
  end
  if spellTargetFaction ~= faction then
    self.logger:Fail("Spell target (%s) is not %s", spellTargetName, faction)
    return false
  end

  self.logger:Pass("Spell target (%s) is %s", spellTargetName, faction)
  return true
end