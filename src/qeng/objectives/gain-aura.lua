local _, addon = ...
local tokens = addon.QuestScriptTokens

local objective = addon.QuestEngine:NewObjective("gain-aura")

objective:AddShorthandForm(tokens.PARAM_AURA)

objective:AddParameter(tokens.PARAM_TEXT, {
  defaultValue = {
    log = "Gain %a",
    progress = "%a gained",
    quest = "Gain the %a aura[%xyz: while in %xyz][%i: while having %i][%e: while wearing %e]",
    full = "Gain the %a aura[%xyz: while in %xyrz][%i: while having %i][%e: while wearing %e]"
  },
})

objective:AddCondition(tokens.PARAM_AURA, { required = true })
objective:AddCondition(tokens.PARAM_EQUIP)
objective:AddCondition(tokens.PARAM_ITEM)
objective:AddCondition(tokens.PARAM_ZONE)
objective:AddCondition(tokens.PARAM_SUBZONE)
objective:AddCondition(tokens.PARAM_COORDS)

objective:EvaluateOnQuestStart(true)
objective:AddGameEvent("UNIT_AURA", function(target) return target == "player" end)