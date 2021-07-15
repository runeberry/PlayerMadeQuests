local _, addon = ...

local time = addon.G.time
local GetGuildInfo = addon.G.GetGuildInfo
local UnitFullName = addon.G.UnitFullName
local UnitClass = addon.G.UnitClass
local UnitLevel = addon.G.UnitLevel
local UnitFactionGroup = addon.G.UnitFactionGroup
local UnitRace = addon.G.UnitRace
local UnitSex = addon.G.UnitSex
local UnitIsPlayer = addon.G.UnitIsPlayer
local IsInGroup = addon.G.IsInGroup
local IsInRaid = addon.G.IsInRaid

------------------
-- Data Caching --
------------------

local playerDataCache = {}

local function getCacheKeys(playerName, dataField)
  return playerName..":"..dataField, playerName..":"..dataField.."@"
end

local function getPlayerData(playerName, dataField)
  local cacheKey = getCacheKeys(playerName, dataField)
  return playerDataCache[cacheKey]
end

local function cachePlayerData(playerName, dataField, dataValue)
  if dataValue == nil then return end
  local cacheKey, timestampKey = getCacheKeys(playerName, dataField)
  local timestamp = time()

  playerDataCache[cacheKey] = dataValue
  playerDataCache[timestampKey] = timestamp
end

local function cacheUnitData(unitId, dataField, dataValue)
  if dataValue == nil or not UnitIsPlayer(unitId) then return end
  local playerName = UnitFullName(unitId)
  cachePlayerData(playerName, dataField, dataValue)
end

--- For debugging only
function addon:GetPlayerDataCache()
  return playerDataCache
end

function addon:FlushPlayerDataCache()
  local length = addon:tlen(playerDataCache)
  playerDataCache = {}
  addon.Logger:Trace("Flushed player data cache (%i fields)", length)
end

---------------------------
-- Player Data by UnitId --
---------------------------

function addon:GetPlayerName(unitId)
  unitId = unitId or "player"
  local name = UnitFullName(unitId)
  return name
end

function addon:GetPlayerRealm(unitId)
  unitId = unitId or "player"
  local _, realm = UnitFullName(unitId)
  return realm
end

function addon:GetPlayerLevel(unitId)
  unitId = unitId or "player"
  local level = UnitLevel(unitId)

  cacheUnitData(unitId, "Level", level)
  return level
end

function addon:GetPlayerClass(unitId)
  unitId = unitId or "player"
  local class = UnitClass(unitId)

  cacheUnitData(unitId, "Class", class)
  return class
end

function addon:GetPlayerFaction(unitId)
  unitId = unitId or "player"
  local faction = UnitFactionGroup(unitId)

  cacheUnitData(unitId, "Faction", faction)
  return faction
end

function addon:GetPlayerRace(unitId)
  unitId = unitId or "player"
  local race = UnitRace(unitId)

  cacheUnitData(unitId, "Race", race)
  return race
end

function addon:GetPlayerGender(unitId)
  unitId = unitId or "player"
  local sex = UnitSex(unitId)

  if sex == 2 then
    sex = "male"
  elseif sex == 3 then
    sex = "female"
  else
    return nil
  end

  cacheUnitData(unitId, "Sex", sex)
  return sex
end

function addon:GetPlayerGuildName(unitId)
  unitId = unitId or "player"
  local guildName = GetGuildInfo(unitId)

  cacheUnitData(unitId, "Guild", guildName)
  return guildName
end

-------------------------
-- Player Data by Name --
-------------------------

function addon:GetPlayerLevelByName(playerName)
  return getPlayerData(playerName, "Level")
end

function addon:GetPlayerClassByName(playerName)
  return getPlayerData(playerName, "Class")
end

function addon:GetPlayerFactionByName(playerName)
  return getPlayerData(playerName, "Faction")
end

function addon:GetPlayerRaceByName(playerName)
  return getPlayerData(playerName, "Race")
end

function addon:GetPlayerGenderByName(playerName)
  return getPlayerData(playerName, "Gender")
end

function addon:GetPlayerGuildNameByName(playerName)
  return getPlayerData(playerName, "Guild")
end

------------
-- Events --
------------

local function cacheAllUnitData(unitId)
  if not UnitIsPlayer(unitId) then return end
  local playerName = addon:GetPlayerName(unitId)
  if not playerName then return end

  addon:GetPlayerLevel(unitId)
  addon:GetPlayerClass(unitId)
  addon:GetPlayerFaction(unitId)
  addon:GetPlayerRace(unitId)
  addon:GetPlayerGender(unitId)
  addon:GetPlayerGuildName(unitId)

  addon.Logger:Trace("Cached data for player: %s", playerName)
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