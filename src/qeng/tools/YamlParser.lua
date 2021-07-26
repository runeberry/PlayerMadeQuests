local _, addon = ...
local logger = addon.Logger:NewLogger("YamlParser")
local ParseYaml = addon.ParseYaml
local assertf, errorf = addon.assertf, addon.errorf

local parameters = addon.QuestEngine.definitions.parameters

local function tryConvert(val, toType)
  local ok, converted = pcall(addon.ConvertValue, addon, val, toType)
  if ok then return converted end
end

-- Each parse mode returns: "checkpoint name", { checkpoint parameters }
local parseMode
parseMode = {
  -- mode: (Shorthand String)
  -- yaml: - kill 5 Chicken
  --  lua: "kill 5 Chicken"
  [1] = function(obj)
    local words = addon:SplitWords(obj)
    local objName, args = words[1], {}

    -- All types will be strings when converting from shorthand
    -- Try to convert them in the same way the yaml parser would
    for i, word in ipairs(words) do
      if i > 1 then
        local converted = tryConvert(word, "number")
        if not converted then
          converted = tryConvert(word, "boolean")
          if not converted then
            converted = word
          end
        end
        args[i-1] = converted
      end
    end

    return objName, args
  end,
  -- mode: (Shorthand string, with optional colon)
  -- yaml: - kill: 5 Chicken
  --  lua: { kill = "5 Chicken" }
  [2] = function(obj)
    local str
    for k, v in pairs(obj) do
      str = k.." "..v
      break
    end
    return parseMode[1](str)
  end,
  -- mode: (Kinda malformed table, but I'll allow it)
  -- yaml: - kill:
  --         goal: 5
  --         target: Chicken
  --  lua: { kill = "yaml.null", goal = 5, target = "Chicken" }
  [3] = function(obj)
    for k, v in pairs(obj) do
      if tostring(v) == "yaml.null" then
        local objName = k
        obj[k] = nil
        return objName, obj
      end
    end
  end,
  -- mode: (Properly formed table, flow style also works)
  -- yaml: - kill:
  --           goal: 5
  --           target: Chicken
  --  lua: { kill = { goal = 5, target = "Chicken" } }
  [4] = function(obj)
    for k, v in pairs(obj) do
      return k, v
    end
  end,
}

local function determineParseMode(cp)
  if type(cp) == "string" then
    return 1
  elseif type(cp) == "table" then
    local len, v1 = 0, nil
    for k, v in pairs(cp) do
      len = len + 1
      if len == 1 then
        v1 = v
      end
    end
    if len == 1 then
      if type(v1) == "string" then
        return 2
      elseif type(v1) == "table" then
        return 4
      end
    else
      return 3
    end
  end
end

local function validateYamlPropertyType(val, ty)
  if ty == "array" then
    -- Special type: array - Must be a table with only ordered properties
    if type(val) ~= "table" then return false end
    local ipairsLen = #val
    local pairsLen = addon:tlen(val)
    -- Assert that there are no unordered (pairs) properties, only 0 or more array properties
    if ipairsLen ~= pairsLen then return false end
  else
    if type(val) ~= ty then return false end
  end

  return true
end

local function validateYamlProperty(name, val, prop)
  if not prop then return end -- No rule to validate against
  assertf(type(name) == "string", "'%s' is not a valid YAML property", tostring(name))

  local tval
  if prop.type then
    if type(prop.type) == "string" then
      -- Treat a single property type as a one-item array
      prop.type = { prop.type }
    end

    for _, t in ipairs(prop.type) do
      if validateYamlPropertyType(val, t) then
        tval = t -- Type found, stop checking
        break
      end
    end

    if not tval then
      errorf("Expected type %s for property '%s'", table.concat(prop.type, " or "), name)
    end
  else
    -- Property type is not validate, use whatever type the value already is
    tval = type(val)
  end

  if prop.properties then
    if tval == "array" then
      for i, v in ipairs(val) do
        validateYamlProperty(name.."["..tostring(i).."]", v, prop.properties)
      end
    elseif tval == "table" then
      for k, v in pairs(val) do
        validateYamlProperty(name.."."..tostring(k), v, prop.properties[k])
      end
    end
  end
end

--------------------
-- Public methods --
--------------------

function addon:ParseYaml(str, valdoc)
  local parsed = ParseYaml(str)

  if valdoc then
    for name, val in pairs(parsed) do
      validateYamlProperty(name, val, valdoc[name])
    end
  end

  return parsed
end

--- Translates any potential shorthand item into a standardized form.
--- @param rawValue any - the user input value to translate
function addon:ParseShorthand(rawValue)
  local mode = determineParseMode(rawValue)
  assertf(mode, "Cannot determine how to parse YAML shorthand item (raw type: %s)", type(rawValue))

  local name, args = parseMode[mode](rawValue)
  assert(name, "Cannot determine name of shorthand item")

  return name, args
end

--- Given a set of ordered property names, assigns
--- @param args table - an array of values to be assigned
--- @param params table - an array of parameter names to assign shorthand values to
--- @return table assigned - key/value pairs of the assigned args values
function addon:AssignShorthandArgs(args, params)
  assertf(params and #params > 0, "Failed to assign shorthand args: no parameters provided")
  assertf(#args > 0, "Failed to assign shorthand args: no arg values received")
  assertf(#args <= #params, "Failed to assign shorthand args: Received %i arg values but only %i parameters", #args, #params)

  local assigned = {}
  local skipped = 0

  logger:Trace("--- Beginning shorthand arg assignment ---")
  for i, paramName in ipairs(params) do
    local parameter = parameters[paramName]
    assertf(parameter, "'%s' is not a recognized parameter", paramName)

    local argValue = args[i - skipped]
    if parameter:IsValid(argValue) then
      logger:Trace("assignment: %s = %s", paramName, tostring(argValue))
      assigned[paramName] = argValue
    else
      -- Loop to the next shorthand param, but try with this arg value again
      logger:Trace("skipping: %s != %s", paramName, tostring(argValue))
      skipped = skipped + 1
    end
  end

  return assigned
end