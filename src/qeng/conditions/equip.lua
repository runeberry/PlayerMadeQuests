local _, addon = ...

local IsEquippedItem = addon.G.IsEquippedItem

local condition = addon.QuestEngine:NewCondition(addon.QuestScriptTokens.PARAM_EQUIP)
condition:AllowType("string")
condition:AllowMultiple(true)

function condition:OnParse(arg)
  if type(arg) == "string" then
    arg = { arg }
  end
  return addon:DistinctSet(arg)
end

function condition:Evaluate(itemNames)
  for itemName in pairs(itemNames) do
    if IsEquippedItem(itemName) then
      -- Player is wearing one of the specified items
      self.logger:Pass("Found equipped item: %s", itemName)
      return true
    end
  end

  -- Player does not have any of the specified items
  self.logger:Fail("No equipment match found")
  return false
end