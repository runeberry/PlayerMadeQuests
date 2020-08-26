local _, addon = ...
local loader = addon.QuestScriptLoader

local condition = loader:NewCondition(addon.QuestScriptTokens.PARAM_AURA)
condition:AllowType("string")
condition:AllowMultiple(true)

function condition:Parse(arg)
  if type(arg) == "string" then
    arg = { arg }
  end
  return addon:DistinctSet(arg)
end

function condition:Evaluate(auraNames)
  local playerAuras = addon:GetPlayerAuraNames()

  for expectedAura in pairs(auraNames) do
    if playerAuras[expectedAura] then
      -- If any expected aura is found in the player's aura list, then evaluation passes
      self.logger:Pass("Found aura match: %s", expectedAura)
      return true
    end
  end

  -- Otherwise, no expected auras were found
  self.logger:Fail("No aura match found (%i checked)", addon:tlen(playerAuras))
  return false
end