local _, addon = ...
local GetSpellInfo = addon.G.GetSpellInfo
local logger = addon.Logger:NewLogger("Spells")

------------------
-- SPELL LOOKUP --
------------------

-- Based on: https://wow.gamepedia.com/API_GetSpellInfo
local function parseSpellInfo(idOrName, spell)
  spell = spell or {}
  local info = { GetSpellInfo(idOrName) }

  if not info[1] then return end

  spell.name = info[1]
  spell.rank = info[2]
  spell.icon = info[3]
  spell.castTime = info[4]
  spell.minRange = info[5]
  spell.maxRange = info[6]
  spell.spellId = info[7]

  return spell
end

local function getSpell(idOrName)
  return parseSpellInfo(idOrName)
end

--- Looks up a spell by name or spellId.
--- Note that name lookups will only succeed if the player currently knows the spell.
--- todo: add scanning and caching so this ^ isn't an issue
function addon:LookupSpell(idOrName)
  addon:ParseIdOrName(idOrName)

  local spell = getSpell(idOrName)
  assert(spell, "Unknown spell: "..idOrName)

  return spell
end

function addon:LookupSpellSafe(idOrName)
  addon:ParseIdOrName(idOrName)
  return getSpell(idOrName)
end
