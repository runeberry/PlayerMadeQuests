local _, addon = ...

local condition = addon.QuestEngine:NewCondition(addon.QuestScriptTokens.PARAM_SPELLTARGETCLASS)
condition:AllowType("string")
condition:AllowValues(addon.WOW_CLASS_NAMES)
condition:AllowMultiple(true)

function condition:OnParse(arg)
  if type(arg) == "string" then
    arg = { arg }
  end

  return addon:DistinctSet(arg)
end

function condition:Evaluate(classes)
  local spellTargetName = addon.LastSpellCast.targetName
  if not spellTargetName then
    self.logger:Fail("No unit was targeted with the last spell")
    return false
  end

  local spellTargetClass = addon:GetUnitClassByName(spellTargetName)
  if not spellTargetClass then
    self.logger:Fail("Spell target (%s) class unknown", spellTargetName)
    return false
  end
  if not classes[spellTargetClass] then
    self.logger:Fail("Spell target (%s) class does not match (%s)", spellTargetName, spellTargetClass)
    return false
  end

  self.logger:Pass("Spell target (%s) class matches (%s)", spellTargetName, spellTargetClass)
  return true
end