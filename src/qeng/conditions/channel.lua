local _, addon = ...

local condition = addon.QuestEngine:NewCondition(addon.QuestScriptTokens.PARAM_CHANNEL)
condition:AllowType("string")
condition:AllowMultiple(true)

function condition:OnParse(arg)
  if type(arg) == "string" then
    arg = { arg }
  end

  -- Lowercase all args for case-insensitive comparison
  for i, v in ipairs(arg) do
    if v then
      arg[i] = v:lower()
    end
  end

  return addon:DistinctSet(arg)
end

function condition:Evaluate(channels)
  -- Get the channel of the last chat message spoken by the player
  local channel = addon.LastChatChannel

  if not channel then
    self.logger:Fail("Chat channel not specified")
    return false
  end

  if channels[channel] then
    self.logger:Pass("Chat spoken in channel: %s", channel)
    return true
  end

  self.logger:Fail("Chat spoken in channel: %s", channel)
  return false
end