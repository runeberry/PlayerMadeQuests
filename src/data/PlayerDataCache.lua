local _, addon = ...
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

function addon.PlayerDataCache:GetPlayerDataByName(playerName, playerRealm, dataField, includeTimestamp)
  if not isCacheReady() then return end

  local cacheKey = getCacheKey(playerName, playerRealm)
  local playerData = self:FindByID(cacheKey)

  if not dataField then
    if includeTimestamp then
      -- Return the whole cached object and timestamp
      return playerData, playerData["@"]
    else
      -- Return the whole cached object
      return playerData
    end

  elseif playerData then
    if includeTimestamp then
      -- Return the specified field value and the timestamp at which it was cached
      return playerData[dataField], playerData[dataField.."@"]
    else
      -- Return only the specified field value
      return playerData[dataField]
    end
  end
end

function addon.PlayerDataCache:SetPlayerDataByName(playerName, playerRealm, dataField, dataValue)
  if playerName == nil or dataField == nil or dataValue == nil then return end
  if not isCacheReady() then return end

  local cacheKey = getCacheKey(playerName, playerRealm)
  local playerData = self:FindByID(cacheKey) or {
    Name = playerName,
    Realm = playerRealm or currentRealm,
    FullName = cacheKey,
  }

  local timestamp = time()
  playerData["@"] = timestamp
  playerData[dataField] = dataValue
  playerData[dataField.."@"] = timestamp

  self:Save(playerData)
end