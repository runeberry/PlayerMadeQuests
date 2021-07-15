local _, addon = ...

local condition = addon.QuestEngine:NewCondition(addon.QuestScriptTokens.PARAM_TARGETGUILD)
condition:AllowType("string")
condition:AllowMultiple(true)

function condition:OnParse(arg)
  if type(arg) == "string" then
    arg = { arg }
  end

  return addon:DistinctSet(arg)
end

function condition:Evaluate(guilds)
  local targetGuild = addon:GetPlayerGuildName("target")

  if not targetGuild then
    self.logger:Fail("Target has no guild")
    return false
  end
  if not guilds[targetGuild] then
    self.logger:Fail("Target guild does not match (%s)", targetGuild)
    return false
  end

  self.logger:Pass("Target guild matches (%s)", targetGuild)
  return true
end