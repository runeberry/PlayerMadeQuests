local _, addon = ...
local logger = addon.QuestEngine.ObjectiveLogger
local loader = addon.QuestScriptLoader
local tokens = addon.QuestScriptTokens

loader:AddScript(tokens.PARAM_ITEM, tokens.METHOD_PARSE, function(itemNames)
  local t = type(itemNames)
  assert(t == "string" or t == "table", t.." is not a valid type for "..tokens.PARAM_ITEM)

  if t == "string" then
    itemNames = { itemNames }
  end

  return addon:DistinctSet(itemNames)
end)

loader:AddScript(tokens.PARAM_ITEM, tokens.METHOD_EVAL, function(obj, itemNames)
  local qty
  for itemName in pairs(itemNames) do
    qty = addon:GetPlayerItemQuantity(itemName)
    if qty > 0 then
      -- Player has at least one of one of the specified items
      logger:Debug(logger.pass.."Found (%i) of item: %s", qty, itemName)
      return true
    end
  end

  -- Player does not have any of the specified items
  logger:Debug(logger.fail.."No item match found")
  return false
end)