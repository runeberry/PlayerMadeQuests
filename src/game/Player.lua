local _, addon = ...
local GetGuildInfo = addon.G.GetGuildInfo
local UnitFullName = addon.G.UnitFullName
local UnitClass = addon.G.UnitClass
local UnitLevel = addon.G.UnitLevel
local UnitFactionGroup = addon.G.UnitFactionGroup
local UnitRace = addon.G.UnitRace
local UnitSex = addon.G.UnitSex

function addon:GetPlayerName()
  local name = UnitFullName("player")
  return name
end

function addon:GetPlayerRealm()
  local _, realm = UnitFullName("player")
  return realm
end

function addon:GetPlayerLevel()
  return UnitLevel("player")
end

function addon:GetPlayerClass()
  return UnitClass("player")
end

function addon:GetPlayerFaction()
  return UnitFactionGroup("player")
end

function addon:GetPlayerRace()
  local race = UnitRace("player")
  return race
end

function addon:GetPlayerGender()
  local sex = UnitSex("player")
  if sex == 2 then return "male" end
  if sex == 3 then return "female" end
end

function addon:GetPlayerGuildName()
  local name = GetGuildInfo("player")
  return name
end