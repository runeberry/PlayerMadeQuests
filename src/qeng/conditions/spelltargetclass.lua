local _, addon = ...

local condition = addon.QuestEngine:NewCondition(addon.QuestScriptTokens.PARAM_SPELLTARGETCLASS)
condition:AllowType("string")
condition:AllowValues(addon.WOW_CLASS_NAMES)
condition:AllowMultiple(true)

function condition:OnValidate(arg)
  if type(arg) == "string" then
    addon:GetClassNameById(addon.WOW_CLASS_IDS_BY_NAME[arg])
  else
    for _, a in ipairs(arg) do
      addon:GetClassNameById(addon.WOW_CLASS_IDS_BY_NAME[a])
    end
  end
end

function condition:OnParse(arg)
  if type(arg) == "string" then
    arg = { arg }
  end

  for i, a in ipairs(arg) do
    arg[i] = addon.WOW_CLASS_IDS_BY_NAME[a]
  end

  return addon:DistinctSet(arg)
end

function condition:Evaluate(classIds)
  local spellTargetName = addon.LastSpellCast.targetName
  if not spellTargetName then
    self.logger:Fail("No unit was targeted with the last spell")
    return false
  end

  local spellTargetClassId = addon:GetUnitClassByName(spellTargetName)
  if not spellTargetClassId then
    self.logger:Fail("Spell target (%s) class unknown", spellTargetName)
    return false
  end

  local spellTargetClassName = addon:GetClassNameById(spellTargetClassId)
  if not classIds[spellTargetClassId] then
    self.logger:Fail("Spell target (%s) class does not match (%s)", spellTargetName, spellTargetClassName)
    return false
  end

  self.logger:Pass("Spell target (%s) class matches (%s)", spellTargetName, spellTargetClassName)
  return true
end