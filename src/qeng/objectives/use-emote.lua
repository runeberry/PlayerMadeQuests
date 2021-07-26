local _, addon = ...
local tokens = addon.QuestScriptTokens
local UnitGUID = addon.G.UnitGUID

local objective = addon.QuestEngine:NewObjective("use-emote")

objective:AddShorthandForm(tokens.PARAM_EMOTE, tokens.PARAM_GOAL, tokens.PARAM_TARGET)

objective:AddParameter(tokens.PARAM_GOAL)
objective:AddParameter(tokens.PARAM_SAMETARGET)
objective:AddParameter(tokens.PARAM_TEXT, {
  defaultValue = {
    log = "/%em[%t: with %an %t][%g2: %p/%g]",
    progress = "/%em[%t: with %an %t]: %p/%g",
    quest = "/%em[%t: with %g3 %t|[%g2: %g2 times]][%xysz: in %xysz][%a: while having %a][%i: while having %i][%e: while wearing %e]",
    full = "Use emote /%em[%t: on %g3 %t|[%g2: %g2 times]][%xyz: in %xyrz][%a: while having %a][%i: while having %i][%e: while wearing %e]"
  },
})

objective:AddCondition(tokens.PARAM_EMOTE, { required = true })
objective:AddCondition(tokens.PARAM_AURA)
objective:AddCondition(tokens.PARAM_EQUIP)
objective:AddCondition(tokens.PARAM_ITEM)
objective:AddCondition(tokens.PARAM_TARGET)
objective:AddCondition(tokens.PARAM_TARGETCLASS, { alias = "class" })
objective:AddCondition(tokens.PARAM_TARGETFACTION, { alias = "faction" })
objective:AddCondition(tokens.PARAM_TARGETGUILD, { alias = "guild" })
objective:AddCondition(tokens.PARAM_TARGETLEVEL, { alias = "level" })
objective:AddCondition(tokens.PARAM_ZONE)
objective:AddCondition(tokens.PARAM_SUBZONE)
objective:AddCondition(tokens.PARAM_COORDS)

-- Returns true if the objective is to target a specific player, false otherwise
local function hasSpecificPlayerTarget(obj, targetGuid)
  -- Specific targets must be defined by the 'target' condition
  if not obj.conditions[tokens.PARAM_TARGET] then return end

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
  local targetGuid = UnitGUID("target")
  if hasSpecificPlayerTarget(obj, targetGuid) then return result end

  return addon:EvaluateUniqueTargetForObjective(self, obj, targetGuid)
end

objective:AddGameEvent("CHAT_MSG_TEXT_EMOTE", function(msg, playerName)
  if playerName == addon:GetPlayerName() and msg then
    -- Only handle emotes that the player performs
    addon.LastEmoteMessage = msg
    return true
  end
end)