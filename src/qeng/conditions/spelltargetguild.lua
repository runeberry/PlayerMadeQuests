local _, addon = ...

local condition = addon.QuestEngine:NewCondition(addon.QuestScriptTokens.PARAM_SPELLTARGETGUILD)
condition:AllowType("string")
condition:AllowMultiple(true)

function condition:OnParse(arg)
  if type(arg) == "string" then
    arg = { arg }
  end

  return addon:DistinctSet(arg)
end

function condition:Evaluate(guilds)
  local spellTargetName = addon.LastSpellCast.targetName
  if not spellTargetName then
    self.logger:Fail("No unit was targeted with the last spell")
    return false
  end

  local spellTargetGuild = addon:GetUnitGuildNameByName(spellTargetName)
  if not spellTargetGuild then
    self.logger:Fail("Spell target (%s) has no guild", spellTargetName)
    return false
  end
  if not guilds[spellTargetGuild] then
    self.logger:Fail("Spell target (%s) guild does not match (%s)", spellTargetName, spellTargetGuild)
    return false
  end

  self.logger:Pass("Spell target (%s) guild matches (%s)", spellTargetName, spellTargetGuild)
  return true
end