local _, addon = ...
local tokens = addon.QuestScriptTokens

local objective = addon.QuestEngine:NewObjective("kill")

objective:AddShorthandForm(tokens.PARAM_GOAL, tokens.PARAM_KILLTARGET)

objective:AddParameter(tokens.PARAM_GOAL)
objective:AddParameter(tokens.PARAM_TEXT, {
  defaultValue = {
    log = "%t %p/%g",
    progress = "%t slain: %p/%g",
    quest = "Kill [%g2 ]%t[%xyz: in %xyz][%a: while having %a][%i: while having %i][%e: while wearing %e]",
    full = "Kill [%g2 ]%t[%xyz: in %xyrz][%a: while having %a][%i: while having %i][%e: while wearing %e]"
  },
})

objective:AddCondition(tokens.PARAM_AURA)
objective:AddCondition(tokens.PARAM_EQUIP)
objective:AddCondition(tokens.PARAM_ITEM)
objective:AddCondition(tokens.PARAM_KILLTARGET, { required = true, alias = tokens.PARAM_TARGET })
objective:AddCondition(tokens.PARAM_ZONE)
objective:AddCondition(tokens.PARAM_SUBZONE)
objective:AddCondition(tokens.PARAM_COORDS)

objective:AddCombatLogEvent("PARTY_KILL", function(cl)
  addon.LastPartyKill = cl
  return true
end)