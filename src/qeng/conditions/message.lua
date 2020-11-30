local _, addon = ...

local condition = addon.QuestEngine:NewCondition(addon.QuestScriptTokens.PARAM_MESSAGE)
condition:AllowType("string")

function condition:OnParse(arg)
  -- All message patterns are case-insenstive matches
  return arg:lower()
end

function condition:Evaluate(message)
  local lastMessage = addon.LastChatMessage

  if not lastMessage then
    self.logger:Fail("Last chat message not found")
    return false
  end

  lastMessage = lastMessage:lower()

  if lastMessage:match(message) then
    self.logger:Pass("Chat message matched pattern: %s", message)
    return true
  end

  self.logger:Fail("Chat message did not match pattern: %s", message)
  return false
end