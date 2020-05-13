local _, addon = ...
addon:traceFile("rules/emote.lua")

local QuestEngine = addon.QuestEngine
local GetUnitName = addon.G.GetUnitName

local rule = QuestEngine:NewRule("emote")

function rule:GetDisplayText(obj)
  local str = obj:GetConditionDisplayText("emote", "Use an emote")
  if obj:HasCondition("target") then
    str = str.." with "..obj:GetConditionDisplayText("target")
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