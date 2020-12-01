local _, addon = ...

local condition = addon.QuestEngine:NewCondition(addon.QuestScriptTokens.PARAM_RECIPIENT)
condition:AllowType("string")
condition:AllowMultiple(true)

function condition:OnParse(arg)
  if type(arg) == "string" then
    arg = { arg }
  end

  -- Recipient names ARE case-sensitive, do not lowercase them

  return addon:DistinctSet(arg)
end

function condition:Evaluate(recipients)
  -- Get the recipient of the last whisper spoken by the player
  local recipient = addon.LastChatRecipient

  if not recipient then
    self.logger:Fail("Chat message had no recipient")
    return false
  end

  if recipients[recipient] then
    self.logger:Pass("Whisper sent to: %s", recipient)
    return true
  end

  self.logger:Fail("Whisper sent to: %s", recipient)
  return false
end