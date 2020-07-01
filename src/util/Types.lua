local _, addon = ...

local boolTable = {
  ["true"] = true,
  ["enable"] = true,
  ["on"] = true,
  ["yes"] = true,

  ["false"] = false,
  ["disable"] = false,
  ["off"] = false,
  ["no"] = false,
}

local converters = {
  ["string:number"] = function(str)
    return tonumber(str)
  end,
  ["string:boolean"] = function(str)
    str = str:lower()
    if boolTable[str] ~= nil then return boolTable[str] end
  end,
  ["number:string"] = function(num)
    return tostring(num)
  end,
  ["number:boolean"] = function(num)
    if num == 0 then return false elseif num == 1 then return true end
  end,
  ["boolean:string"] = function(bool)
    if bool then return "true" else return "false" end
  end,
  ["boolean:number"] = function(bool)
    if bool then return 1 else return 0 end
  end
}

function addon:ConvertValue(val, toType)
  assert(toType, "A type must be specified for conversion")

  local fromType = type(val)
  if fromType == toType then return val end

  local converter = converters[fromType..":"..toType]
  assert(converter, "Type conversion unavailable: "..fromType.." to "..toType)

  local converted = converter(val)
  assert(converted ~= nil, "Failed to convert value "..tostring(val).." from type "..fromType.." to "..toType)

  return converted
end

function addon:TryConvertString(str)
  local converted = converters["string:number"](str)
  if converted then return converted end

  converted = converters["string:boolean"](str)
  if converted then return converted end

  return str
end