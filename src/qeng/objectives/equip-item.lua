local _, addon = ...
local tokens = addon.QuestScriptTokens

local objective = addon.QuestEngine:NewObjective("equip-item")

objective:AddShorthandForm(tokens.PARAM_EQUIP)

objective:AddParameter(tokens.PARAM_TEXT, {
  defaultValue = {
    log = "Equip %e",
    progress = "%e equipped",
    quest = "Equip %e[%xyz: while in %xyz][%a: while having %a][%i: while having %i]",
    full = "Equip %e[%xyz: while in %xyrz][%a: while having %a][%i: while having %i]"
  },
})

objective:AddCondition(tokens.PARAM_EQUIP, { required = true })
objective:AddCondition(tokens.PARAM_AURA)
objective:AddCondition(tokens.PARAM_ITEM)
objective:AddCondition(tokens.PARAM_ZONE)
objective:AddCondition(tokens.PARAM_SUBZONE)
objective:AddCondition(tokens.PARAM_COORDS)

objective:EvaluateOnQuestStart(true)
objective:AddAppEvent("PlayerInventoryChanged")