local _, addon = ...

local parameter = addon.QuestEngine:NewParameter(addon.QuestScriptTokens.PARAM_REWARDMONEY)
parameter:AllowType("number", "string")

local function parseMoneyString(str)
  local value = 0

  local g, s, c = str:match("(%d-)[Gg]"), str:match("(%d-)[Ss]"), str:match("(%d-)[Cc]")

  if g then
    value = value + (10000 * tonumber(g))
  end
  if s then
    value = value + (100 * tonumber(s))
  end
  if c then
    value = value + tonumber(c)
  end

  return value
end

local function getMoneyValue(rawValue)
  local value = 0
  if type(rawValue) == "number" then
    value = rawValue
  elseif type(rawValue) == "string" then
    value = parseMoneyString(rawValue)
  end
  return value
end

function parameter:OnValidate(rawValue)
  return getMoneyValue(rawValue) >= 0, "Reward money must be greater than or equal to 0"
end

function parameter:OnParse(rawValue)
  return getMoneyValue(rawValue)
end