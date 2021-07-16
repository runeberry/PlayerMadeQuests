local _, addon = ...
local tokens = addon.QuestScriptTokens
local GetUnitName = addon.G.GetUnitName

local objective = addon.QuestEngine:NewObjective("kill")

objective:AddShorthandForm(tokens.PARAM_GOAL, tokens.PARAM_KILLTARGET)

objective:AddParameter(tokens.PARAM_GOAL)
objective:AddParameter(tokens.PARAM_SAMETARGET)
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
objective:AddCondition(tokens.PARAM_KILLTARGET, { alias = "target" })
objective:AddCondition(tokens.PARAM_KILLTARGETCLASS, { alias = "class" })
objective:AddCondition(tokens.PARAM_KILLTARGETFACTION, { alias = "faction" })
objective:AddCondition(tokens.PARAM_KILLTARGETGUILD, { alias = "guild" })
objective:AddCondition(tokens.PARAM_KILLTARGETLEVEL, { alias = "level" })
objective:AddCondition(tokens.PARAM_ZONE)
objective:AddCondition(tokens.PARAM_SUBZONE)
objective:AddCondition(tokens.PARAM_COORDS)

-- Returns true if the objective is to target a specific player, false otherwise
local function hasSpecificPlayerTarget(obj, targetGuid)
  -- Specific targets must be defined by the 'target' condition
  if not obj.conditions[tokens.PARAM_KILLTARGET] then return end

  -- During AfterEvaluate, we know we have a matching target on LastSpellCast
  -- So we can analyze that guid to determine if the successful target was, in fact, a Player
  return addon:ParseGUID(targetGuid).type == "Player"
end

function objective:AfterEvaluate(result, obj)
  -- Only concerned with objectives that have passed and have a goal > 1
  if not result or obj.goal <= 1 then return result end

  -- If flagged, then killing the same target repeatedly is allowed
  if obj.parameters and obj.parameters[tokens.PARAM_SAMETARGET] then return result end

  -- This is an unusual edge case to avoid otherwise incompletable quests to cast spells on multiple
  -- different player targets w/ the same name
  -- (bug: you could cheese a quest to "kill 10 Devilsaur" by killing a player named "Devilsaur" 10 times)
  local targetGuid = addon.LastPartyKill.destGuid
  if hasSpecificPlayerTarget(obj, targetGuid) then return result end

  return addon:EvaluateUniqueTargetForObjective(self, obj, targetGuid)
end

local petDamageTable = {}

objective:AddCombatLogEvent("PARTY_KILL", function(cl)
  addon.LastPartyKill = cl
  if cl.sourceGuid then
    petDamageTable[cl.sourceGuid] = nil
  end
  return true
end)

addon:OnConfigLoaded(function()
  if addon.Config:GetValue("FEATURE_PET_KILLS") then
    -- Pet kills don't fire a PARTY_KILL event, but we can estimate when your pet has killed something.
    -- Any unit that dies which your pet previously attacked will grant you credit for party kills

    local function rememberPetDamage(cl)
      if cl.destName == GetUnitName("pet") and cl.sourceGuid then
        petDamageTable[cl.sourceGuid] = true -- Remember pet's guid so we can attribute a unit kill to the pet
      end
    end

    addon.CombatLogEvents:Subscribe("SWING_DAMAGE", rememberPetDamage)
    addon.CombatLogEvents:Subscribe("SPELL_CAST_SUCCESS", rememberPetDamage)

    objective:AddCombatLogEvent("UNIT_DIED", function(cl)
      if cl.destGuid and petDamageTable[cl.destGuid] then
        objective.logger:Trace("Attributing kill to pet: %s", cl.destGuid)
        addon.LastPartyKill = cl
        petDamageTable[cl.destGuid] = nil
        return true
      end
    end)
  end
end)