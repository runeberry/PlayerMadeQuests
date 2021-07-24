local _, addon = ...

local condition = addon.QuestEngine:NewCondition(addon.QuestScriptTokens.PARAM_KILLTARGETFACTION)
condition:AllowType("string")
condition:AllowValues(addon.WOW_FACTIONS)

function condition:Evaluate(faction)
  local killTargetName = addon.LastPartyKill.destName
  local killTargetFaction = addon:GetUnitFactionByName(killTargetName)

  if not killTargetFaction then
    self.logger:Fail("Kill target (%s) has no faction", killTargetName)
    return false
  end
  if killTargetFaction ~= faction then
    self.logger:Fail("Kill target (%s) is not %s", killTargetName, faction)
    return false
  end

  self.logger:Pass("Kill target (%s) is %s", killTargetName, faction)
  return true
end