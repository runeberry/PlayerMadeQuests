local _, addon = ...
local tokens = addon.QuestScriptTokens
local UnitExists, GetUnitName, UnitGUID = addon.G.UnitExists, addon.G.GetUnitName, addon.G.UnitGUID
local CheckInteractDistance = addon.G.CheckInteractDistance

local objective = addon.QuestEngine:NewObjective("talk-to")

objective:AddShorthandForm(tokens.PARAM_GOAL, tokens.PARAM_TARGET)

objective:AddParameter(tokens.PARAM_GOAL)
objective:AddParameter(tokens.PARAM_TEXT, {
  defaultValue = {
    log = "Talk to %t[%g2: %p/%g]",
    progress = "Talk to %t: %p/%g",
    quest = "Talk to [%g2 ]%t[%xyz: in %xyz][%a: while having %a][%i: while having %i][%e: while wearing %e]",
    full = "Talk to [%g2 ]%t[%xyz: in %xyrz][%a: while having %a][%i: while having %i][%e: while wearing %e]"
  },
})

objective:AddCondition(tokens.PARAM_AURA)
objective:AddCondition(tokens.PARAM_EQUIP)
objective:AddCondition(tokens.PARAM_ITEM)
objective:AddCondition(tokens.PARAM_TARGET, { required = true })
objective:AddCondition(tokens.PARAM_ZONE)
objective:AddCondition(tokens.PARAM_SUBZONE)
objective:AddCondition(tokens.PARAM_COORDS)

function objective:AfterEvaluate(result, obj)
  -- Only concerned with objectives that have passed and have a goal > 1
  if not result or obj.goal <= 1 then return result end
  return addon:EvaluateUniqueTargetForObjective(self, obj, UnitGUID("target"))
end

local targetExistsFilter = function() return UnitExists("target") end

local talkEmoteMsg
local isTalkEmoteFilter = function(msg, playerName)
  if not talkEmoteMsg then
    talkEmoteMsg = addon.Emotes:FindByCommand("/talk").targeted
  end
  if playerName == GetUnitName("player") and msg and UnitExists("target") then
    local talkEmoteMsgTargeted = talkEmoteMsg:gsub("%%t", GetUnitName("target"))
    if msg == talkEmoteMsgTargeted then
      if CheckInteractDistance("target", 5) then
        addon.QuestEvents:Publish(tokens.OBJ_TALKTO)
      else
        addon.Logger:Trace("Not close enough to /talk to target")
      end
    end
  end
end

objective:AddGameEvent("AUCTION_HOUSE_SHOW", targetExistsFilter)
objective:AddGameEvent("BANKFRAME_OPENED", targetExistsFilter)
objective:AddGameEvent("GOSSIP_SHOW", targetExistsFilter)
objective:AddGameEvent("MERCHANT_SHOW", targetExistsFilter)
objective:AddGameEvent("PET_STABLE_SHOW", targetExistsFilter)
objective:AddGameEvent("QUEST_DETAIL", targetExistsFilter)
objective:AddGameEvent("QUEST_PROGRESS", targetExistsFilter)

objective:AddGameEvent("CHAT_MSG_TEXT_EMOTE", isTalkEmoteFilter)