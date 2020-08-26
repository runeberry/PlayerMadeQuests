local _, addon = ...
local loader = addon.QuestScriptLoader
local UnitExists, GetUnitName = addon.G.UnitExists, addon.G.GetUnitName

-- Expected chat messages indexed by the objective they're expected for
local expectedEmoteMessages = {}

local condition = loader:NewCondition(addon.QuestScriptTokens.PARAM_EMOTE)
condition:AllowType("string")
condition:AllowMultiple(true)

function condition:Parse(arg)
  if type(arg) == "string" then
    arg = { arg }
  end
  return addon:DistinctSet(arg)
end

function condition:Evaluate(emoteNames, obj)
  local eem = expectedEmoteMessages[obj.id]
  local expectTargetedEmote = obj.conditions[addon.QuestScriptTokens.PARAM_TARGET]

  if expectTargetedEmote then
    self.logger:Trace("        Expecting emote to be targeted")
  end

  -- Determine the expected emote messages, then cache the result
  if not eem then
    eem = {}

    for emoteName in pairs(emoteNames) do
      local emote = addon.Emotes:FindByCommand(emoteName)
      if emote then
        -- The targeted version of an emote is always allowed
        table.insert(eem, emote.targeted)
        if not expectTargetedEmote then
          -- but the untargeted version is only allowed if no target condition is specified
          table.insert(eem, emote.untargeted)
        end
      end
    end
    expectedEmoteMessages[obj.id] = eem
  end

  local pem = addon.LastEmoteMessage
  if not pem then return end

  if UnitExists("target") then
    -- Replace the emote message from chat with a %t placeholder
    -- so we can compare to the generic emote message.
    local targetName = GetUnitName("target")
    pem = pem:gsub(targetName, "%%t")
    self.logger:Trace("        Last emote message modified to: %s", pem)
  end

  -- If the emote matches matches the message of any of the
  -- expected emotes, then the condition is true.
  for _, em in pairs(eem) do
    if pem == em then
      self.logger:Pass("Emote match found: %s", em)
      return true
    end
  end

  self.logger:Fail("No emote match found")
  return false
end
