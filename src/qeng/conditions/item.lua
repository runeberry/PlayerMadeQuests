local _, addon = ...
local loader = addon.QuestScriptLoader

local condition = loader:NewCondition(addon.QuestScriptTokens.PARAM_ITEM)
condition:AllowType("string")
condition:AllowMultiple(true)

function condition:Parse(arg)
  if type(arg) == "string" then
    arg = { arg }
  end
  return addon:DistinctSet(arg)
end

function condition:Evaluate(itemNames)
  local qty
  for itemName in pairs(itemNames) do
    qty = addon:GetPlayerItemQuantity(itemName)
    if qty > 0 then
      -- Player has at least one of one of the specified items
      self.logger:Pass("Found (%i) of item: %s", qty, itemName)
      return true
    end
  end

  -- Player does not have any of the specified items
  self.logger:Fail("No item match found")
  return false
end