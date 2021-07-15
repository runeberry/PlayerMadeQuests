local _, addon = ...

local UnitIsPlayer = addon.G.UnitIsPlayer
local UnitFullName = addon.G.UnitFullName
local time = addon.G.time

addon.PlayerDataCache = addon:NewRepository("PlayerData", "FullName")
addon.PlayerDataCache:SetSaveDataSource("PlayerDataCache")
addon.PlayerDataCache:EnableWrite(true)
addon.PlayerDataCache:EnableDirectRead(true)
addon.PlayerDataCache:EnableCompression(false)
addon.PlayerDataCache:EnableGlobalSaveData(true)

local currentRealm

local function isCacheReady()
  if not currentRealm then
    currentRealm = addon:GetPlayerRealm()
  end
  return currentRealm and true
end

local function getCacheKey(playerName, playerRealm)
  playerRealm = playerRealm or currentRealm
  return playerName.."-"..playerRealm
end

function addon.PlayerDataCache:GetPlayerData(playerName, playerRealm, dataField)
  if not isCacheReady() then return end

  local cacheKey = getCacheKey(playerName, playerRealm)
  local pdata = self:FindByID(cacheKey)
  if pdata then return pdata[dataField] end
end

function addon.PlayerDataCache:SetPlayerData(playerName, playerRealm, dataField, dataValue)
  if playerName == nil or dataField == nil or dataValue == nil then return end
  if not isCacheReady() then return end

  local cacheKey = getCacheKey(playerName, playerRealm)
  local timestamp = time()

  local pdata = self:FindByID(cacheKey) or {
    id = cacheKey,
    Name = playerName,
    Realm = playerRealm or currentRealm,
    FullName = cacheKey,
  }
  pdata[dataField] = dataValue
  pdata[dataField.."@"] = timestamp

  self:Save(pdata)
end

function addon.PlayerDataCache:SetUnitData(unitId, dataField, dataValue)
  if dataValue == nil or not UnitIsPlayer(unitId) then return end
  local playerName, playerRealm = UnitFullName(unitId)
  addon.PlayerDataCache:SetPlayerData(playerName, playerRealm, dataField, dataValue)
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