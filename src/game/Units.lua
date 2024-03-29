local _, addon = ...
local PlayerDataCache, NpcDataCache = addon.PlayerDataCache, addon.NpcDataCache

local UnitIsPlayer = addon.G.UnitIsPlayer
local GetGuildInfo = addon.G.GetGuildInfo
local UnitFullName = addon.G.UnitFullName
local UnitClass = addon.G.UnitClass
local UnitLevel = addon.G.UnitLevel
local UnitFactionGroup = addon.G.UnitFactionGroup
local UnitRace = addon.G.UnitRace
local UnitSex = addon.G.UnitSex
local IsInGroup = addon.G.IsInGroup
local IsInRaid = addon.G.IsInRaid

local function setCacheValue(unitId, dataField, dataValue)
  if dataField == nil or dataValue == nil then return end

  local unitName, unitRealm = UnitFullName(unitId)
  if not unitName then return end

  if UnitIsPlayer(unitId) then
    PlayerDataCache:SetPlayerDataByName(unitName, unitRealm, dataField, dataValue)
  else
    NpcDataCache:SetNpcDataByName(unitName, dataField, dataValue)
  end
end

local function getCacheValue(unitName, unitRealm, dataField)
  if not unitName then return end
  local dataValue

  -- If a unitRealm is provided, then we can assume this is a player and skip the NPC check
  if unitRealm == nil then
    dataValue = NpcDataCache:GetNpcDataByName(unitName, dataField)
    if dataValue then return dataValue end
  end

  -- If a unitRealm is provided, or no NPC was found, then check for a player by this name
  dataValue = PlayerDataCache:GetPlayerDataByName(unitName, unitRealm, dataField)
  return dataValue
end

--------------------
-- Data by UnitId --
--------------------

function addon:GetUnitName(unitId)
  local name = UnitFullName(unitId)
  return name
end

function addon:GetUnitRealm(unitId)
  local _, realm = UnitFullName(unitId)
  return realm
end

function addon:GetUnitLevel(unitId)
  local level = UnitLevel(unitId)

  if UnitIsPlayer(unitId) then
    setCacheValue(unitId, "Level", level)
  else
    -- NPCs can have different levels for units of the same name
    local unitName = UnitFullName(unitId)

    local cachedLevel = getCacheValue(unitName, nil, "Level")
    if not cachedLevel or level < cachedLevel then
      -- The unit's singular "level" will be considered the lowest level it's been observed at
      setCacheValue(unitId, "Level", level)
    end

    local cachedMinLevel = getCacheValue(unitName, nil, "LevelMin")
    if not cachedMinLevel or level < cachedMinLevel then
      setCacheValue(unitId, "LevelMin", level)
    end

    local cachedMaxLevel = getCacheValue(unitName, nil, "LevelMax")
    if not cachedMaxLevel or level > cachedMaxLevel then
      setCacheValue(unitId, "LevelMax", level)
    end
  end

  return level
end

function addon:GetUnitClass(unitId, localized)
  -- Only attempt to cache class for players
  if not UnitIsPlayer(unitId) then return end

  local classLocal, _, classId = UnitClass(unitId)
  setCacheValue(unitId, "ClassId", classId)

  if localized then
    return classLocal
  end

  return classId
end

function addon:GetUnitFaction(unitId, localized)
  local factionId, factionLocal = UnitFactionGroup(unitId)
  setCacheValue(unitId, "FactionId", factionId)
  addon:SetFactionNameById(factionId, factionLocal)

  if localized then
    return factionLocal
  end

  return factionId
end

function addon:GetUnitRace(unitId, localized)
  local raceLocal, _, raceId = UnitRace(unitId)
  setCacheValue(unitId, "RaceId", raceId)

  if localized then
    return raceLocal
  end

  return raceId
end

function addon:GetUnitSex(unitId, localized)
  local sexId = UnitSex(unitId)
  setCacheValue(unitId, "SexId", sexId)

  if localized then
    return addon:GetSexNameById(sexId)
  end

  return sexId
end

function addon:GetUnitGuildName(unitId)
  local guildName = GetGuildInfo(unitId)

  setCacheValue(unitId, "Guild", guildName)
  return guildName
end

-----------------
-- Player Data --
-----------------

function addon:GetPlayerName()
  return addon:GetUnitName("player")
end

function addon:GetPlayerRealm()
  return addon:GetUnitRealm("player")
end

function addon:GetPlayerLevel()
  return addon:GetUnitLevel("player")
end

function addon:GetPlayerClass(localized)
  return addon:GetUnitClass("player", localized)
end

function addon:GetPlayerFaction(localized)
  return addon:GetUnitFaction("player", localized)
end

function addon:GetPlayerRace(localized)
  return addon:GetUnitRace("player", localized)
end

function addon:GetPlayerSex(localized)
  return addon:GetUnitSex("player", localized)
end

function addon:GetPlayerGuildName()
  return addon:GetUnitGuildName("player")
end

-----------------------
-- Unit Data by Name --
-----------------------

function addon:GetUnitLevelByName(name, realm)
  return getCacheValue(name, realm, "Level")
end

function addon:GetUnitClassByName(name, realm, localized)
  local classId = getCacheValue(name, realm, "ClassId")
  if classId and localized then return addon:GetClassNameById(classId) end
  return classId
end

function addon:GetUnitFactionByName(name, realm, localized)
  local factionId = getCacheValue(name, realm, "FactionId")
  if factionId and localized then return addon:GetFactionNameById(factionId) end
  return factionId
end

function addon:GetUnitRaceByName(name, realm, localized)
  local raceId = getCacheValue(name, realm, "RaceId")
  if raceId and localized then return addon:GetRaceNameById(raceId) end
  return raceId
end

function addon:GetUnitSexByName(name, realm, localized)
  local sexId = getCacheValue(name, realm, "SexId")
  if sexId and localized then return addon:GetSexNameById(sexId) end
  return sexId
end

function addon:GetUnitGuildNameByName(name, realm)
  return getCacheValue(name, realm, "Guild")
end

------------
-- Events --
------------

local function cacheAllUnitData(unitId)
  local unitName = UnitFullName(unitId)
  if not unitName then return end -- Unit does not exist

  addon:GetUnitLevel(unitId)
  addon:GetUnitClass(unitId)
  addon:GetUnitFaction(unitId)
  addon:GetUnitRace(unitId)
  addon:GetUnitSex(unitId)
  addon:GetUnitGuildName(unitId)

  addon.Logger:Trace("Cached data for unit: %s", unitName)
end

local function cacheGroupData()
  if IsInRaid() then
    for i = 1,40 do
      cacheAllUnitData("raid"..tostring(i))
    end
  elseif IsInGroup() then
    for i = 1,4 do
      cacheAllUnitData("party"..tostring(i))
    end
  end
end

addon:OnBackendReady(function()
  addon.GameEvents:Subscribe("PLAYER_TARGET_CHANGED", function()
    cacheAllUnitData("target")
  end)

  addon.GameEvents:Subscribe("UPDATE_MOUSEOVER_UNIT", function()
    cacheAllUnitData("mouseover")
  end)

  addon.GameEvents:Subscribe("GROUP_JOINED", cacheGroupData)
  addon.GameEvents:Subscribe("GROUP_ROSTER_UPDATE", cacheGroupData)
end)