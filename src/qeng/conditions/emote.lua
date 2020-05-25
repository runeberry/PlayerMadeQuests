local _, addon = ...
local UnitExists = addon.G.UnitExists
local GetUnitName = addon.G.GetUnitName
addon:traceFile("conditions/emote.lua")

local condition = addon.QuestEngine:NewCondition("emote")

function condition:CheckCondition(obj, emoteNames)
  local eem = obj:GetMetadata("ExpectedEmoteMessages")
  local expectTargetedEmote = obj:HasCondition("target")

  if eem == nil then
    eem = {}

    for emoteName in pairs(emoteNames) do
      local emote = addon.Emotes:FindByCommand(emoteName)
      if emote then
        if expectTargetedEmote then
          table.insert(eem, emote.targeted)
        else
          table.insert(eem, emote.untargeted)
        end
      end
    end
    obj:SetMetadata("ExpectedEmoteMessages", eem)
  end

  local pem = obj:GetMetadata("PlayerEmoteMessage")
  if expectTargetedEmote then
    -- Replace the emote message from chat with a %t placeholder
    -- so we can compare to the generic emote message.
    local targetExists = UnitExists("target")
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
end