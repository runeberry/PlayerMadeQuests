local _, addon = ...
local logger = addon.QuestEngineLogger
local tokens = addon.QuestScriptTokens
local GetUnitName = addon.G.GetUnitName

local objective = addon.QuestEngine:NewObjective("use-emote")

objective:AddShorthandForm(tokens.PARAM_EMOTE, tokens.PARAM_GOAL, tokens.PARAM_TARGET)

objective:AddParameter(tokens.PARAM_GOAL)
objective:AddParameter(tokens.PARAM_TEXT, {
  defaultValue = {
    log = "/%em[%t: with %t][%g2: %p/%g]",
    progress = "/%em[%t: with %t]: %p/%g",
    quest = "/%em[%t: with [%g2 ]%t|[%g2: %g2 times]][%xysz: in %xysz][%a: while having %a][%i: while having %i][%e: while wearing %e]",
    full = "Use emote /%em[%t: on [%g2 ]%t|[%g2: %g2 times]][%xyz: in %xyrz][%a: while having %a][%i: while having %i][%e: while wearing %e]"
  },
})

objective:AddCondition(tokens.PARAM_EMOTE, { required = true })
objective:AddCondition(tokens.PARAM_AURA)
objective:AddCondition(tokens.PARAM_EQUIP)
objective:AddCondition(tokens.PARAM_ITEM)
objective:AddCondition(tokens.PARAM_TARGET)
objective:AddCondition(tokens.PARAM_ZONE)
objective:AddCondition(tokens.PARAM_SUBZONE)
objective:AddCondition(tokens.PARAM_COORDS)

objective:AddGameEvent("CHAT_MSG_TEXT_EMOTE", function(msg, playerName)
  if playerName == GetUnitName("player") and msg then
    -- Only handle emotes that the player performs
    addon.LastEmoteMessage = msg
    return true
  end
end)