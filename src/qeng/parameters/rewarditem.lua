local _, addon = ...

--[[
  Supports items expressed as the following:
    number - the itemId, such as 13444
    string - the item name, such as "Major mana potion"
    table - { id = number, name = string, quantity = number }
--]]

local parameter = addon.QuestEngine:NewParameter(addon.QuestScriptTokens.PARAM_REWARDITEM)
parameter:AllowType("number", "string", "table")
parameter:AllowMultiple(true)

local function validateItem(idOrName)
  if not idOrName then
    return false, "Reward item id or name must be specified"
  end

  if not addon:LookupItemSafe(idOrName) then
    return false, string.format("No item exists with id or name: %s", tostring(idOrName))
  end

  return true
end

local function parseItem(idOrName, quantity)
  local item = addon:LookupItem(idOrName)

  return {
    id = item.id,
    quantity = quantity,
  }
end

function parameter:OnValidate(rawValue)
  if type(rawValue) == "table" then
    if #rawValue > 1 then
      -- Parameter is an array of items, validate each item within
      for i, innerValue in ipairs(rawValue) do
        local result, err = self:OnValidate(innerValue)
        if not result then
          return result, string.format("Reward #%i is invalid: %s", i, err)
        end
      end
    else
      -- Parameter is a single item expressed as a table
      local result, err = validateItem(rawValue.id or rawValue.name)
      if not result then return result, err end

      if rawValue.quantity then
        assert(type(rawValue.quantity) == "number", "Reward item quantity must be expressed as a number")
        assert(rawValue.quantity > 0, "Reward item quantity must be greater than 0")
      end
    end
  else
    -- Parameter is a single item expressed as a number (id) or string (name)
    local result, err = validateItem(rawValue)
    if not result then return result, err end
  end

  return true
end

--[[
  Translated format is an array of:
    id: number
    quantity: number
--]]
function parameter:OnParse(arg)
  local items

  if type(arg) == "table" then
    if #arg > 1 then
      -- Parameter is an array of items...
      items = {}
      for _, innerValue in ipairs(arg) do
        if type(innerValue) == "table" then
          -- ...expressed as a table
          items[#items+1] = parseItem(innerValue.id or innerValue.name, innerValue.quantity)
        else
          -- ...expressed as a number (id) or string (name)
          items[#items+1] = parseItem(innerValue)
        end
      end
    else
      -- Parameter is a single item expressed as a table
      items = { parseItem(arg.id or arg.name, arg.quantity) }
    end
  else
    -- Parameter is a single item expressed as a number (id) or string (name)
    items = { parseItem(arg) }
  end

  return items
end