local _, addon = ...

local condition = addon.QuestEngine:NewCondition(addon.QuestScriptTokens.PARAM_KILLTARGET)
condition:AllowType("string")
condition:AllowMultiple(true)

function condition:OnParse(arg)
  if type(arg) == "string" then
    arg = { arg }
  end
  return addon:DistinctSet(arg)
end

function condition:Evaluate(unitNames, cp)
  local targetUnitName = addon.LastPartyKill.destName

  if not targetUnitName then
    -- No unit is targeted
    self.logger:Fail("No unit is targeted")
    return false
  end
  if unitNames[targetUnitName] == nil then
    -- The targeted unit's name does not match the objective's unit name
    self.logger:Fail("Target name does not match")
    return false
  end

  self.logger:Pass("Target name matches (%s)", targetUnitName)
  return true
end