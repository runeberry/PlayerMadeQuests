local _, addon = ...
local logger = addon.QuestEngine.ObjectiveLogger
local loader = addon.QuestScriptLoader
local tokens = addon.QuestScriptTokens
local UnitExists, GetUnitName = addon.G.UnitExists, addon.G.GetUnitName

-- Expected chat messages indexed by the objective they're expected for
local expectedEmoteMessages = {}

loader:AddScript(tokens.PARAM_EMOTE, tokens.METHOD_PARSE, function(emoteNames)
  local t = type(emoteNames)
  assert(t == "string" or t == "table", t.." is not a valid type for "..tokens.PARAM_EMOTE)

  if t == "string" then
    emoteNames = { emoteNames }
  end

  return addon:DistinctSet(emoteNames)
end)

loader:AddScript(tokens.PARAM_EMOTE, tokens.METHOD_EVAL, function(obj, emoteNames)
  local eem = expectedEmoteMessages[obj.id]
  local expectTargetedEmote = obj.conditions[tokens.PARAM_TARGET]

  if expectTargetedEmote then
    logger:Trace("        Expecting emote to be targeted")
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
    logger:Trace("        Last emote message modified to: %s", pem)
  end

  -- If the emote matches matches the message of any of the
  -- expected emotes, then the condition is true.
  for _, em in pairs(eem) do
    if pem == em then
      logger:Debug(logger.pass.."Emote match found: %s", em)
      return true
    end
  end

  logger:Debug(logger.fail.."No emote match found")
  return false
end)
