local _, addon = ...

local condition = addon.QuestEngine:NewCondition(addon.QuestScriptTokens.PARAM_SPELLTARGET)
condition:AllowType("string")
condition:AllowMultiple(true)

function condition:OnParse(arg)
  if type(arg) == "string" then
    arg = { arg }
  end
  return addon:DistinctSet(arg)
end

function condition:Evaluate(unitNames, cp)
  local targetUnitName = addon.LastSpellCast.targetName

  if not targetUnitName then
    self.logger:Fail("No unit was targeted with the last spell")
    return false
  end
  if not unitNames[targetUnitName] then
    -- The targeted unit's name does not match the objective's unit name
    self.logger:Fail("Spell target name does not match")
    return false
  end

  self.logger:Pass("Spell target name matches (%s)", targetUnitName)
  return true
end