local _, addon = ...

local condition = addon.QuestEngine:NewCondition(addon.QuestScriptTokens.PARAM_TARGETCLASS)
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
  local targetClass = addon:GetUnitClass("target")

  if not targetClass then
    self.logger:Fail("Target has no class")
    return false
  end
  if not classes[targetClass] then
    self.logger:Fail("Target class does not match (%s)", targetClass)
    return false
  end

  self.logger:Pass("Target class matches (%s)", targetClass)
  return true
end