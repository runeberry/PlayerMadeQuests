local _, addon = ...

local condition = addon.QuestEngine:NewCondition(addon.QuestScriptTokens.PARAM_KILLTARGETCLASS)
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
  local killTargetName = addon.LastPartyKill.destName
  local killTargetClassId = addon:GetUnitClassByName(killTargetName)

  if not killTargetClassId then
    self.logger:Fail("Kill target (%s) class unknown", killTargetName)
    return false
  end

  local killTargetClassName = addon:GetClassNameById(killTargetClassId)
  if not classIds[killTargetClassId] then
    self.logger:Fail("Kill target (%s) class does not match (%s)", killTargetName, killTargetClassName)
    return false
  end

  self.logger:Pass("Kill target (%s) class matches (%s)", killTargetName, killTargetClassName)
  return true
end