local _, addon = ...
local GetUnitName = addon.G.GetUnitName
addon:traceFile("rules/emote.lua")

local rule = addon.QuestEngine:NewRule("emote")

function rule:GetDisplayText(obj)
  local str = ""
  if obj:HasCondition("emote") then
    str = addon:GetConditionValueText(obj.conditions["emote"])
  else
    str = "Use an emote"
  end
  if obj:HasCondition("target") then
    str = str.." with "..addon:GetConditionValueText(obj.conditions["target"])
  end
  return str
end

function rule:BeforeCheckConditions(obj, msg)
  obj:SetMetadata("PlayerEmoteMessage", msg)
end

addon:onload(function()
  addon.GameEvents:Subscribe("CHAT_MSG_TEXT_EMOTE", function(msg, playerName)
    if playerName == GetUnitName("player") then
      -- Only handle emotes that the player performs
      addon.RuleEvents:Publish(rule.name, msg)
    end
  end)
end)