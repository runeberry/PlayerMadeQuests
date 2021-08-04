local _, addon = ...
local asserttype = addon.asserttype

addon.QuestChains = addon:NewRepository("QuestChain", "chainId")
local QuestChains = addon.QuestChains
QuestChains:SetSaveDataSource("QuestChains")
QuestChains:EnableWrite(true)
QuestChains:EnableCompression(true)
QuestChains:EnableTimestamps(true)

-- Normalize chainId to remove any capitalization, spacing, or punctuation differences
local function createChainId(chainName)
  local playerName = addon:GetPlayerName()
  local playerRealm = addon:GetPlayerRealm()
  local chainNameSimple = chainName:lower():gsub("^%s+", ""):gsub("%s+$", ""):gsub("%W", "-"):gsub("[-]+", "-")

  return string.format("chain-%s-%s-%s", playerName, playerRealm, chainNameSimple)
end

function QuestChains:GetOrCreateChain(chainName)
  asserttype(chainName, "string", "chainName", "GetOrCreateChain")

  local chainId = createChainId(chainName)

  local existing = self:FindByID(chainId)
  if existing then
    if existing.name ~= chainName then
      -- Chain display name takes on whatever capitalization, punctuation, etc. is present
      -- in the most recent Save. This is a workaround for managing a chain's exact display name
      -- since there's
      existing.name = chainName
      self:Save(existing)
    end
    return existing
  end

  local chain = {
    chainId = chainId,
    name = chainName,
    questIds = {}
  }

  self:Save(chain)
  return chain
end