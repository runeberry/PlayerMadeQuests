local _, addon = ...
local tokens = addon.QuestScriptTokens
local GetUnitName = addon.G.GetUnitName

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

function objective:AfterEvaluate(result, obj)
  -- Only concerned with objectives that have passed and have a goal > 1
  if not result or obj.goal <= 1 then return result end
  return addon:EvaluateUniqueTargetForObjective(self, obj, addon.LastPartyKill.destGuid)
end

local petDamageTable = {}

objective:AddCombatLogEvent("PARTY_KILL", function(cl)
  addon.LastPartyKill = cl
  if cl.sourceGuid then
    petDamageTable[cl.sourceGuid] = nil
  end
  return true
end)

-- Pet kills don't fire a PARTY_KILL event, but we can estimate when your pet has killed something.
-- Any unit that dies which your pet previously attacked will grant you credit for party kills

local function isPetDamage(cl)
  if cl.destName == GetUnitName("pet") and cl.sourceGuid then
    petDamageTable[cl.sourceGuid] = true -- Remember pet's guid so we can attribute a unit kill to the pet
    return true
  end
end

objective:AddCombatLogEvent("SWING_DAMAGE", isPetDamage)
objective:AddCombatLogEvent("SPELL_CAST_SUCCESS", isPetDamage)

objective:AddCombatLogEvent("UNIT_DIED", function(cl)
  if cl.destGuid and petDamageTable[cl.destGuid] then
    objective.logger:Trace("Attributing kill to pet: %s", cl.destGuid)
    petDamageTable[cl.destGuid] = nil
    return true
  end
end)