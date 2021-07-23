local _, addon = ...

local condition = addon.QuestEngine:NewCondition(addon.QuestScriptTokens.PARAM_KILLTARGETCLASS)
condition:AllowType("string")
condition:AllowValues(addon.WOW_ALL_CLASSES)
condition:AllowMultiple(true)

function condition:OnParse(arg)
  if type(arg) == "string" then
    arg = { arg }
  end

  return addon:DistinctSet(arg)
end

function condition:Evaluate(classes)
  local killTargetName = addon.LastPartyKill.destName
  local killTargetClass = addon:GetUnitClassByName(killTargetName)

  if not killTargetClass then
    self.logger:Fail("Kill target (%s) class unknown", killTargetName)
    return false
  end
  if not classes[killTargetClass] then
    self.logger:Fail("Kill target (%s) class does not match (%s)", killTargetName, killTargetClass)
    return false
  end

  self.logger:Pass("Kill target (%s) class matches (%s)", killTargetName, killTargetClass)
  return true
end