local _, addon = ...
addon:traceFile("conditions/emote.lua")
local QuestEngine, tokens = addon.QuestEngine, addon.QuestScript.tokens
local UnitExists, GetUnitName = addon.G.UnitExists, addon.G.GetUnitName

QuestEngine:AddScript(tokens.COND_EMOTE_SCRIPT, function(obj, emoteNames)
  local eem = obj:GetMetadata("ExpectedEmoteMessages")
  local expectTargetedEmote = obj:HasCondition("target")

  if eem == nil then
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
    obj:SetMetadata("ExpectedEmoteMessages", eem)
  end

  local pem = obj:GetMetadata("PlayerEmoteMessage")
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
