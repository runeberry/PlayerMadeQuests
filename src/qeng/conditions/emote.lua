local _, addon = ...
addon:traceFile("conditions/emote.lua")
local compiler, tokens = addon.QuestScriptCompiler, addon.QuestScript.tokens
local UnitExists, GetUnitName = addon.G.UnitExists, addon.G.GetUnitName

-- Expected chat messages indexed by the objective they're expected for
local expectedEmoteMessages = {}

compiler:AddScript(tokens.PARAM_EMOTE, tokens.METHOD_CHECK_COND, function(obj, emoteNames)
  local eem = expectedEmoteMessages[obj.id]
  local expectTargetedEmote = obj.conditions[tokens.PARAM_TARGET]

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
  end

  -- If the emote matches matches the message of any of the
  -- expected emotes, then the condition is true.
  for _, em in pairs(eem) do
    if pem == em then
      return true
    end
  end
end)
