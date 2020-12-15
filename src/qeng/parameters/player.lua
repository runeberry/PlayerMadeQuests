local _, addon = ...

local parameter = addon.QuestEngine:NewParameter(addon.QuestScriptTokens.PARAM_PLAYER)
parameter:AllowType("string")
parameter:AllowMultiple(true)

-- Validation based on character naming policy here: https://us.battle.net/support/en/article/34530
local function validatePlayerName(name)
  local length = name:len()
  if length < 2 or length > 12 then
    return false, "Player name must be 2-12 characters"
  end
  if name:match("%d") then
    return false, "Player name must not contain numbers"
  end
  if name:match("-") then
    return false, "Player name must not include '-' (do not include realm)"
  end
  return true
end

function parameter:OnValidate(rawValue)
  if type(rawValue) == "string" then
    return validatePlayerName(rawValue)
  end

  for _, player in ipairs(rawValue) do
    local result, err = validatePlayerName(player)
    if not result then return result, err end
  end

  return true
end

function parameter:OnParse(arg)
  if type(arg) == "string" then
    arg = { arg }
  end

  return addon:DistinctSet(arg)
end