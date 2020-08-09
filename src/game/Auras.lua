local _, addon = ...
local UnitAura = addon.G.UnitAura

-- Returns the aura as a parsed table
-- Info from: https://wow.gamepedia.com/API_UnitAura
local function getPlayerAura(index)
  local info = { UnitAura("player", index) }
  if #info == 0 then return end

  local obj = {
    name = info[1],             -- Localized name
    icon = info[2],             -- FileDataID (number)
    count = info[3],            -- # stacks, 0 if non-stackable
    debuffType = info[4],       -- Magic type (string)
    duration = info[5],         -- Full duration of the aura in seconds
    expirationTime = info[6],   -- When the aura expires (timestamp in seconds)
    source = info[7],           -- unitId that cast the aura ("player", etc.)
    isStealable = info[8],      -- Can be stolen by Spellsteal?
    nameplateShowPersonal = info[9],
    spellId = info[10],         -- Use with GetSpellInfo()
    canApplyAura = info[11],    -- True if the player is capable of applying this aura
    isBossDebuff = info[12],    -- True if cast by a boss
    castByPlayer = info[13],    -- True if it was cast by ANY player
    nameplateShowAll = info[14],
    timeMod = info[15],         -- Used for displaying time left (number)
  }
  -- up to 11 more returns may be available depending on the aura type

  return obj
end

-- Returns detailed information about all of the player's auras
function addon:GetPlayerAuras()
  local i, aura, auras = 1, 0, {}
  while aura do
    aura = getPlayerAura(i)
    if aura then
      auras[i] = aura
      i = i + 1
    end
  end
  return auras
end

-- Returns only the names of the player's current auras as a distinct set
function addon:GetPlayerAuraNames()
  local i, auraName, auraNames = 1, 0, {}
  while auraName do
    auraName = UnitAura("player", i)
    if auraName then
      auraNames[auraName] = true
      i = i + 1
    end
  end
  return auraNames
end