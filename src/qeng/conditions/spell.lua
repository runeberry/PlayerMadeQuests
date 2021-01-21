local _, addon = ...

local condition = addon.QuestEngine:NewCondition(addon.QuestScriptTokens.PARAM_SPELL)
condition:AllowType("string", "number")
condition:AllowMultiple(true)

function condition:OnParse(arg)
  if type(arg) ~= "table" then
    arg = { arg }
  end

  local ids = {}
  for i, a in ipairs(arg) do
    -- Validate that the spell exists and convert everything to spellIds
    local spell = addon:LookupSpell(a)
    ids[i] = spell.spellId
  end

  return addon:DistinctSet(ids)
end

function condition:Evaluate(spells)
  if not addon.LastSpellCast then
    self.logger:Fail("No spell has been cast")
    return false
  end

  local spellMatch = spells[addon.LastSpellCast.spellId]

  if not spellMatch then
    -- Spell does not match by Id, but might match by name
    for _, spellId in ipairs(spells) do
      local spellInfo = addon:LookupSpellSafe(spellId)
      if spellInfo and spellInfo.name == addon.LastSpellCast.name then
        -- Spell matches on name, but not on ID.
        -- Can happen with different ranks of the same spell.
        spellMatch = true
        break
      end
    end
  end

  if not spellMatch then
    self.logger:Fail("Spell does not match: %s (%i)", addon.LastSpellCast.name, addon.LastSpellCast.spellId)
    return false
  end

  self.logger:Pass("Spell matches: %s (%i)", addon.LastSpellCast.name, addon.LastSpellCast.spellId)
  return true
end