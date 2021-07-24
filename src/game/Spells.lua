local _, addon = ...
local GetSpellInfo = addon.G.GetSpellInfo
local GameSpellCache = addon.GameSpellCache
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

  -- note: I wanted to include spell links but GetSpellLink
  -- does not actually return links in classic, only the name

  return spell
end

local function getSpell(idOrName)
  local spellInfo = parseSpellInfo(idOrName)

  if not spellInfo then
    local spellId, spellName = addon:ParseIdOrName(idOrName)
    if spellName then
      -- See if the cache has a spellId associated with this name
      spellId = GameSpellCache:FindSpellID(spellName)
      if spellId then
        spellInfo = parseSpellInfo(spellId)
      end
    end
  end

  if spellInfo then
    GameSpellCache:SaveSpellID(spellInfo.name, spellInfo.spellId)
  end

  return spellInfo
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

------------------------
-- SPELLCAST TRACKING --
------------------------

--[[
  Here are the steps for building the PlayerCastSpell event:
  1. When a spellcast begins, cache the spellId and the name of the spell's target.
  2. When a spellcast ends, set a short timer after which it will be "resolved".
  3. Gather information about the spell from game and CL events.
  4. When the timer is up, look at all info about the spellcast and determine if it was successful.

  When a spell is confirmed successful, fire a PlayerCastSpell event.
--]]

local spellcasts = {} --- Active spellcasts indexed by castId
local spellcastTargets = {} -- The guid of the most recent target of a spell, indexed by spellName
local spellcastResolveDelay = 0.2 -- Time (in seconds) to wait for a combat log event before resolving a spellcast
local spellcastResolveTimers = {} -- Timers set to resolve spellcasts by castId

local function setSpellcastInfo(castId, spellId)
  local spellcast = spellcasts[castId]
  if not spellcast then
    local spellInfo = addon:LookupSpell(spellId)

    spellcast = {
      castId = castId,
      spellId = spellId,
      name = spellInfo.name,
    }

    spellcasts[castId] = spellcast
  end

  -- can add more info to the cast after it's returned
  return spellcast
end

local function resolveSpellcast(castId)
  -- Check if spell already has a resolve timer, don't try to resolve twice
  if spellcastResolveTimers[castId] then return end

  logger:Trace("Starting spellcast resolve timer...")
  spellcastResolveTimers[castId] = addon.Ace:ScheduleTimer(function()
    -- Step 4
    spellcastResolveTimers[castId] = nil
    local spellcast = spellcasts[castId]
    spellcasts[castId] = nil

    if not spellcast then
      logger:Debug("Spellcast resolved: FAIL for %s (%i) - spell was not cached", spellcast.name, spellcast.spellId)
      return
    end

    if not spellcast.success then
      local reason
      if spellcast.interrupted then
        reason = "spell was interrupted"
      elseif spellcast.failed then
        reason = "spell cast failed"
      elseif not spellcast.success then
        reason = "spell status unknown"
      end

      logger:Debug("Spellcast resolved: FAIL for %s (%i) - %s", spellcast.name, spellcast.spellId, reason)
      return
    end

    -- The most recent target GUID of this spell should have been indexed by the combat log event
    spellcast.targetGuid = spellcastTargets[spellcast.name]

    logger:Debug("Spellcast resolved: SUCCESS for %s (%i)", spellcast.name, spellcast.spellId)
    addon.AppEvents:Publish("PlayerCastSpell", spellcast)
  end, spellcastResolveDelay)
end

-- Step 1
addon.GameEvents:Subscribe("UNIT_SPELLCAST_SENT", function(unitId, targetName, castId, spellId)
  if unitId ~= "player" or not castId or not spellId then return end

  local spellcast = setSpellcastInfo(castId, spellId)
  spellcast.targetName = targetName

  logger:Trace("UNIT_SPELLCAST_SENT - %s (%i)", spellcast.name, spellcast.spellId)
end)

-- Step 2
addon.GameEvents:Subscribe("UNIT_SPELLCAST_STOP", function(unitId, castId, spellId)
  if unitId ~= "player" or not castId or not spellId then return end

  local spellcast = setSpellcastInfo(castId, spellId)
  resolveSpellcast(castId)

  logger:Trace("UNIT_SPELLCAST_STOP - %s (%i)", spellcast.name, spellcast.spellId)
end)

-- Step 3 - the following subscriptions gather information about the spellcast
addon.GameEvents:Subscribe("UNIT_SPELLCAST_INTERRUPTED", function(unitId, castId, spellId)
  if unitId ~= "player" or not castId or not spellId then return end

  local spellcast = setSpellcastInfo(castId, spellId)
  spellcast.interrupted = true
  resolveSpellcast(castId)

  logger:Trace("UNIT_SPELLCAST_INTERRUPTED - %s (%i)", spellcast.name, spellcast.spellId)
end)

addon.GameEvents:Subscribe("UNIT_SPELLCAST_SUCCEEDED", function(unitId, castId, spellId)
  if unitId ~= "player" or not castId or not spellId then return end

  local spellcast = setSpellcastInfo(castId, spellId)
  spellcast.success = true
  resolveSpellcast(castId)

  logger:Trace("UNIT_SPELLCAST_SUCCEEDED - %s (%i)", spellcast.name, spellcast.spellId)
end)

addon.GameEvents:Subscribe("UNIT_SPELLCAST_FAILED", function(unitId, castId, spellId)
  if unitId ~= "player" or not castId or not spellId then return end
  logger:Trace("UNIT_SPELLCAST_FAILED")

  local spellcast = setSpellcastInfo(castId, spellId)
  spellcast.failed = true
  resolveSpellcast(castId)

  logger:Trace("UNIT_SPELLCAST_FAILED - %s (%i)", spellcast.name, spellcast.spellId)
end)

-- The cast target's GUID is not available from spellcast events, only from the combat log
-- And the combat log is not aware of the spellId, much less the castId
-- So the best we can do is remember the last GUID that a spell (by name) was successful on
addon.CombatLogEvents:Subscribe("SPELL_CAST_SUCCESS", function(cl)
  if cl.sourceName ~= addon:GetPlayerName() then return end
  logger:Trace("SPELL_CAST_SUCCESS")

  local spellName = cl.raw[13]
  if not spellName then return end

  spellcastTargets[spellName] = cl.destGuid
end)

--------------------
-- SPELL WATCHING --
--------------------

local spellWatchSubKey

local function onSpellCast(spellcast)
  local targetMessage = ""
  if spellcast.targetName then
    targetMessage = " on "..spellcast.targetName
  end
  addon.Logger:Warn("Spell cast: %s (%i)%s", spellcast.name, spellcast.spellId, targetMessage)
end

function addon:ToggleSpellWatch()
  if spellWatchSubKey then
    addon.AppEvents:Unsubscribe("PlayerCastSpell", spellWatchSubKey)
    spellWatchSubKey = nil
    addon.Logger:Warn("No longer watching spell casts.")
  else
    spellWatchSubKey = addon.AppEvents:Subscribe("PlayerCastSpell", onSpellCast)
    addon.Logger:Warn("Watching for spell casts...")
  end
end

-------------------------
-- SPELL DATA SCANNING --
-------------------------

local scanData
local scanFrame

local function spellScanThrottled()
  if not scanData then return end

  local id = scanData.id
  local target = math.min(id + scanData.intensity, scanData.max)

  while id <= target do
    id = id + 1
    if getSpell(id) then -- calling this will trigger a save to cache
      scanData.total = scanData.total + 1
      if scanData.total % scanData.logInterval == 0 then
        addon.Logger:Warn("Scanning spells, %i found...", scanData.total)
      end
    end
  end

  scanData.id = id

  if target == scanData.max then
    addon.Logger:Warn("Spell scan finished: %i spells found.", scanData.total)
    scanData = nil
  end
end

addon:OnGuiStart(function()
  scanFrame = addon.G.CreateFrame("Frame")
  scanFrame:SetScript("OnUpdate", spellScanThrottled)
end)

function addon:ScanSpells(min, max)
  if scanData then
    addon.Logger:Warn("Scan already in progress: currently on %i (%i spells found)", scanData.id, scanData.total)
    return
  end

  -- This default max is 348409 based on a query from: https://wow-query.dev/
  -- But the highest max in classic appears to be much lower
  local maxPossibleSpellId = 50000

  min = addon:ConvertValue(min or 1, "number")
  max = addon:ConvertValue(max or maxPossibleSpellId, "number")
  assert(min and max, "A valid min and max value must be provided")

  -- Creating this object will trigger the scanning OnUpdate script
  scanData = {
    total = 0,
    min = min,
    max = max,
    id = min - 1,
    intensity = addon.Config:GetValue("SPELL_SCAN_INTENSITY"),
    logInterval = addon.Config:GetValue("SPELL_SCAN_LOG_INTERVAL"),
  }

  addon.Logger:Warn("Beginning spell scan - /reload to cancel...")
end