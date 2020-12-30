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

local function extractQuantity(idOrName, quantity)
  if type(idOrName) == "string" and not quantity then
    -- Check if the first word is a number, and treat it as a quantity
    local words = addon:SplitWords(idOrName)
    quantity = tonumber(words[1])
    if quantity then
      table.remove(words, 1)
      idOrName = table.concat(words, " ")
    end
  end
  return idOrName, quantity
end

local function validateItem(idOrName)
  idOrName = extractQuantity(idOrName)

  if not idOrName then
    return false, "Reward item id or name must be specified"
  end

  if not addon:LookupItemSafe(idOrName) then
    return false, string.format("No item exists with id or name: %s.\nTry using the item's ID or scanning with %s",
      tostring(idOrName), addon:Colorize("orange", "/pmq scan-items"))
  end

  return true
end

local function parseItem(idOrName, quantity)
  idOrName, quantity = extractQuantity(idOrName, quantity)

  local item = addon:LookupItem(idOrName)

  return {
    itemId = item.itemId,
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
          return result, string.format("Reward #%i is invalid:\n%s", i, err)
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