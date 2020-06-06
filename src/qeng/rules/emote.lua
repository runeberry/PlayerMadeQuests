local _, addon = ...
addon:traceFile("rules/emote.lua")
local QuestEngine, tokens = addon.QuestEngine, addon.QuestScript.tokens
local GetUnitName = addon.G.GetUnitName

QuestEngine:AddScript(tokens.OBJ_EMOTE_SCRIPT, function(obj, msg)
  obj:SetMetadata("PlayerEmoteMessage", msg)
end)

QuestEngine:AddScript(tokens.OBJ_EMOTE_TEXT, function(obj)
  local str = obj:GetConditionDisplayText("emote", "Use an emote")
  if obj:HasCondition("target") then
    str = str.." with "..obj:GetConditionDisplayText("target")
  end
  return str
end)

addon:onload(function()
  addon.GameEvents:Subscribe("CHAT_MSG_TEXT_EMOTE", function(msg, playerName)
    if playerName == GetUnitName("player") and msg then
      -- Only handle emotes that the player performs
      addon.RuleEvents:Publish(tokens.OBJ_EMOTE, msg)
    end
  end)
end)