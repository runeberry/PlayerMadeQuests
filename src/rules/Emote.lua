local _, addon = ...

local rule = addon.QuestEngine:CreateRule("Emote")
rule.displayText = "Use emote %1 %2 %p/%g"

function rule:CheckObjective(obj, msg)
  -- todo: implement guid tracking so you can't /moo the same tauren twice
  local expectedEmote = obj.args[1] -- todo: look this up when the objective is created and store emote w/ objective
  local expectedUnitName = obj.args[2]

  local targetExists = UnitExists("target")
  local targetName = GetUnitName("target")
  addon:info("exists", targetExists, "name", targetName)

  local isTargetedMessage = false
  if targetExists and targetName then
    -- For comparison, make the message generic by removing the target's name
    local tmsg = msg:gsub(targetName, "%%t")
    if tmsg ~= msg then
      msg = tmsg
      isTargetedMessage = true
      addon:info("Emote is targeted")
    end
  end

  if expectedUnitName then
    addon:info("Expecting targeted")
    if isTargetedMessage == false or targetName ~= expectedUnitName then
      -- If the player did not do a targeted emote, or they targeted a different unit
      -- then do not make any objective progress
        addon:info("Failed target check")
      return false
    end
  end

  -- todo: this lookup can be avoided if we look it up once when the objective is created
  if isTargetedMessage then
    addon:info("Looking up targeted text")
    for _, emote in pairs(addon.EmoteData) do
      if emote.targeted == msg then
        return true
      end
    end
  else
    addon:info("Looking up untargeted text")
    for _, emote in pairs(addon.EmoteData) do
      if emote.untargeted == msg then
        return true
      end
    end
  end
  addon:info("Failed text lookup:", msg)
end

addon:onload(function()
  addon.GameEvents:Subscribe("CHAT_MSG_TEXT_EMOTE", function(msg, playerName)
    if playerName == GetUnitName("player") then
      -- Only handle emotes that the player performs
      addon.RuleEvents:Publish(rule.name, msg)
    end
  end)
end)