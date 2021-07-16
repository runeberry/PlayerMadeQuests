local _, addon = ...
local PlayerDataCache = addon.PlayerDataCache

local GetGuildInfo = addon.G.GetGuildInfo
local UnitFullName = addon.G.UnitFullName
local UnitClass = addon.G.UnitClass
local UnitLevel = addon.G.UnitLevel
local UnitFactionGroup = addon.G.UnitFactionGroup
local UnitRace = addon.G.UnitRace
local UnitSex = addon.G.UnitSex

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

  PlayerDataCache:SetUnitData(unitId, "Level", level)
  return level
end

function addon:GetPlayerClass(unitId)
  unitId = unitId or "player"
  local class = UnitClass(unitId)

  PlayerDataCache:SetUnitData(unitId, "Class", class)
  return class
end

function addon:GetPlayerFaction(unitId)
  unitId = unitId or "player"
  local faction = UnitFactionGroup(unitId)

  PlayerDataCache:SetUnitData(unitId, "Faction", faction)
  return faction
end

function addon:GetPlayerRace(unitId)
  unitId = unitId or "player"
  local race = UnitRace(unitId)

  PlayerDataCache:SetUnitData(unitId, "Race", race)
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

  PlayerDataCache:SetUnitData(unitId, "Sex", sex)
  return sex
end

function addon:GetPlayerGuildName(unitId)
  unitId = unitId or "player"
  local guildName = GetGuildInfo(unitId)

  PlayerDataCache:SetUnitData(unitId, "Guild", guildName)
  return guildName
end

-------------------------
-- Player Data by Name --
-------------------------

function addon:GetPlayerLevelByName(name, realm)
  return PlayerDataCache:GetPlayerData(name, realm, "Level")
end

function addon:GetPlayerClassByName(name, realm)
  return PlayerDataCache:GetPlayerData(name, realm, "Class")
end

function addon:GetPlayerFactionByName(name, realm)
  return PlayerDataCache:GetPlayerData(name, realm, "Faction")
end

function addon:GetPlayerRaceByName(name, realm)
  return PlayerDataCache:GetPlayerData(name, realm, "Race")
end

function addon:GetPlayerGenderByName(name, realm)
  return PlayerDataCache:GetPlayerData(name, realm, "Sex")
end

function addon:GetPlayerGuildNameByName(name, realm)
  return PlayerDataCache:GetPlayerData(name, realm, "Guild")
end