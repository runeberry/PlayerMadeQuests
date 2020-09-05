local _, addon = ...
local logger = addon.QuestEngine.ObjectiveLogger
local tokens = addon.QuestScriptTokens
local GetUnitName = addon.G.GetUnitName


local petDamageTable = {

}
local petName = GetUnitName("pet")

addon:OnQuestEngineReady(function()
  addon.CombatLogEvents:Subscribe("PARTY_KILL", function(cl)
    addon.LastPartyKill = cl
    petDamageTable[cl.sourceGuid] = nil
    addon.QuestEvents:Publish(tokens.OBJ_KILL, cl)
  end)
  addon.CombatLogEvents:Subscribe("SWING_DAMAGE", function(cl)
    if( cl.destName == petName )
    then
      petDamageTable[cl.sourceGuid] = true
    end
  end)
  addon.CombatLogEvents:Subscribe("SPELL_CAST_SUCCESS", function(cl)
    if( cl.destName == petName )
    then
      petDamageTable[cl.sourceGuid] = true
    end
  end)
  addon.CombatLogEvents:Subscribe("UNIT_DIED", function(cl)
    if(petDamageTable[cl.destGuid] == true)
    then
      logger:Trace(cl.destGuid)
      addon.QuestEvents:Publish(tokens.OBJ_KILL, cl)
    end
    petDamageTable[cl.destGuid] = nil
  end)
end)