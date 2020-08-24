local _, addon = ...
local logger = addon.QuestEngine.ObjectiveLogger
local loader = addon.QuestScriptLoader
local tokens = addon.QuestScriptTokens

local IsEquippedItem = addon.G.IsEquippedItem

loader:AddScript(tokens.PARAM_EQUIP, tokens.METHOD_PARSE, function(itemNames)
  local t = type(itemNames)
  assert(t == "string" or t == "table", t.." is not a valid type for "..tokens.PARAM_ITEM)

  if t == "string" then
    itemNames = { itemNames }
  end

  return addon:DistinctSet(itemNames)
end)

loader:AddScript(tokens.PARAM_EQUIP, tokens.METHOD_EVAL, function(obj, itemNames)
  for itemName in pairs(itemNames) do
    if IsEquippedItem(itemName) then
      -- Player is wearing one of the specified items
      logger:Debug(logger.pass.."Found equipped item: %s", itemName)
      return true
    end
  end

  -- Player does not have any of the specified items
  logger:Debug(logger.fail.."No equipment match found")
  return false
end)