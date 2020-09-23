local _, addon = ...
local UnitFullName = addon.G.UnitFullName
local UnitClass = addon.G.UnitClass
local UnitLevel = addon.G.UnitLevel
local UnitFactionGroup = addon.G.UnitFactionGroup

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
  return UnitClass("player"):lower()
end

function addon:GetPlayerFaction()
  return UnitFactionGroup("player"):lower()
end