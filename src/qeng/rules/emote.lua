local _, addon = ...
local GetUnitName = addon.G.GetUnitName
addon:traceFile("rules/emote.lua")

local rule = addon.QuestEngine:NewRule("emote")
rule.displayText = "Use emote %1 %2 %p/%g"

function rule:GetShortText()

end

function rule:GetFullText()

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