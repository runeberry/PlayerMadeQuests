local _, addon = ...

local condition = addon.QuestEngine:NewCondition(addon.QuestScriptTokens.PARAM_TARGETCLASS)
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
  local targetClassId = addon:GetUnitClass("target")

  if not targetClassId then
    self.logger:Fail("Target has no class")
    return false
  end

  local targetClassName = addon:GetClassNameById(targetClassId)
  if not classIds[targetClassId] then
    self.logger:Fail("Target class does not match (%s)", targetClassName)
    return false
  end

  self.logger:Pass("Target class matches (%s)", targetClassName)
  return true
end