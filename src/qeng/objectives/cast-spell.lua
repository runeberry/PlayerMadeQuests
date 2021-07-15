local _, addon = ...
local tokens = addon.QuestScriptTokens

local objective = addon.QuestEngine:NewObjective("cast-spell")

objective:AddShorthandForm(tokens.PARAM_GOAL, tokens.PARAM_SPELL, tokens.PARAM_TARGET)

objective:AddParameter(tokens.PARAM_GOAL)
objective:AddParameter(tokens.PARAM_SAMETARGET)
objective:AddParameter(tokens.PARAM_TEXT, {
  defaultValue = {
    log = "%s[%t: on %t] %p/%g",
    progress = "Cast %s[%t: on %t]: %p/%g",
    quest = "Cast %s[%t:[%g2:[%st:[ on %t %g times]|[ on %g different %t]]|[ on %t]]|[%g2: %g times]][%xyz: in %xyz][%a: while having %a][%i: while having %i][%e: while wearing %e]",
    full = "Cast %s[%t:[%g2:[%st:[ on %t %g times]|[ on %g different %t]]|[ on %t]]|[%g2: %g times]][%xyz: in %xyrz][%a: while having %a][%i: while having %i][%e: while wearing %e]",
  }
})

objective:AddCondition(tokens.PARAM_SPELL, { required = true })
objective:AddCondition(tokens.PARAM_SPELLTARGET, { alias = "target" })
objective:AddCondition(tokens.PARAM_SPELLTARGETCLASS, { alias = "class" })
objective:AddCondition(tokens.PARAM_SPELLTARGETFACTION, { alias = "faction" })
objective:AddCondition(tokens.PARAM_SPELLTARGETGUILD, { alias = "guild" })
objective:AddCondition(tokens.PARAM_SPELLTARGETLEVEL, { alias = "level" })
objective:AddCondition(tokens.PARAM_ITEM)
objective:AddCondition(tokens.PARAM_AURA)
objective:AddCondition(tokens.PARAM_EQUIP)
objective:AddCondition(tokens.PARAM_ZONE)
objective:AddCondition(tokens.PARAM_SUBZONE)
objective:AddCondition(tokens.PARAM_COORDS)

function objective:AfterEvaluate(result, obj)
  -- Only concerned with objectives that have passed, have a target, and have a goal > 1
  if not result or not obj.conditions[tokens.PARAM_SPELLTARGET] or obj.goal <= 1 then return result end
  -- If flagged, then spells cast on the same target repeatedly are allowed
  if obj.parameters and obj.parameters[tokens.PARAM_SAMETARGET] then return result end

  return addon:EvaluateUniqueTargetForObjective(self, obj, addon.LastSpellCast.targetGuid)
end

objective:AddAppEvent("PlayerCastSpell", function(spellcast)
  addon.LastSpellCast = spellcast
  return true
end)