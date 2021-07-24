local _, addon = ...

local condition = addon.QuestEngine:NewCondition(addon.QuestScriptTokens.PARAM_KILLTARGETGUILD)
condition:AllowType("string")
condition:AllowMultiple(true)

function condition:OnParse(arg)
  if type(arg) == "string" then
    arg = { arg }
  end

  return addon:DistinctSet(arg)
end

function condition:Evaluate(guilds)
  local killTargetName = addon.LastPartyKill.destName
  local killTargetGuild = addon:GetUnitGuildNameByName(killTargetName)

  if not killTargetGuild then
    self.logger:Fail("Kill target (%s) has no guild", killTargetName)
    return false
  end
  if not guilds[killTargetGuild] then
    self.logger:Fail("Kill target (%s) guild does not match (%s)", killTargetName, killTargetGuild)
    return false
  end

  self.logger:Pass("Kill target (%s) guild matches (%s)", killTargetName, killTargetGuild)
  return true
end