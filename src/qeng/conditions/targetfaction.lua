local _, addon = ...

local condition = addon.QuestEngine:NewCondition(addon.QuestScriptTokens.PARAM_TARGETFACTION)
condition:AllowType("string")
condition:AllowValues(addon.WOW_FACTIONS)

function condition:Evaluate(faction)
  local playerFaction = addon:GetUnitFaction("target")

  if not playerFaction then
    self.logger:Fail("Target has no faction")
    return false
  end
  if playerFaction ~= faction then
    self.logger:Fail("Target is not %s", faction)
    return false
  end

  self.logger:Pass("Target is %s", faction)
  return true
end