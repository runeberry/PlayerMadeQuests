local _, addon = ...
local assertf, errorf = addon.assertf, addon.errorf

local function validateValue(value, options)
  -- Then, check the list of allowed types. The user input value should match one of those types.
  local vtype = type(value)

  if options.type then
    local isTypeValid
    for _, t in ipairs(options.type) do
      if vtype == t then
        isTypeValid = true
        break
      end
    end

    -- Finally, before failing validation for an invalid type, try to convert the value to an
    -- allowed type. If this type conversion succeeds, then we'll still allow the value and
    -- return the converted value from this method.
    if not isTypeValid and options.type then
      for _, t in ipairs(options.type) do
        local ok, converted = pcall(addon.ConvertValue, addon, value, t)
        if ok then
          -- Quit attempting after the first successful conversion
          value = converted
          isTypeValid = true
          break
        end
      end
    end

    if not isTypeValid then
      local expected = table.concat(options.type, "/")
      return nil, string.format("Value '%s' is not the correct type, must be of type: %s", tostring(value), expected)
    end
  end

  if options.values then
    local isValueValid
    for _, v in ipairs(options.values) do
      if value == v then
        isValueValid = true
        break
      end
    end

    if not isValueValid then
      local expected = table.concat(options.values, ", ")
      return nil, string.format("Value '%s' is not allowed, must be one of: %s", tostring(value), expected)
    end
  end

  -- Return the value (in case it was converted) and no error message
  return value, nil
end

local methods = {
  --- When Validate is run, ensures that the input value matches any one of
  --- these types.
  ["AllowType"] = function(self, ...)
    self.options.type = { ... }
  end,
  --- When Validate is run, then a table of values will always be acceptable
  --- as long as each value inside matches an allowed type.
  ["AllowMultiple"] = function(self, flag)
    if flag == nil then flag = true end
    self.options.multiple = flag
  end,
  --- When Validate is run, then only the values in the provided array will be accepted
  ["AllowValues"] = function(self, values)
    self.options.values = values;
  end,
  --- When this Parameter is not supplied, use this value
  ["SetDefaultValue"] = function(self, val)
    self.options.defaultValue = val
  end,
  --- Validate ensures that the input value is of an acceptable type according
  --- to the rules supplied for this Parameter.
  --- @param self any - this Parameter
  --- @param rawValue any - the input value provided by the user (as parsed from YAML)
  --- @param options table - options specific to this Parameter
  ["Validate"] = function(self, rawValue, options)
    -- Values on options take priority over values on self
    options = addon:MergeOptionsTable(self.options, options)

    -- First, check if the value is nil. If the value is not required, we can safely return now, there is nothing to validate.
    -- But if the value is required, then nil is immediately invalid.
    if rawValue == nil then
      if options.required then
        errorf("Required value '%s' is missing", self.name)
      end
      return
    end

    local validationError
    local traw = type(rawValue)

    local val, err = validateValue(rawValue, options)
    if err then
      validationError = err
    else
      -- If the value had to be type-converted, then the converted value will be returned.
      -- If not, but there was no error, then the same value as rawValue will be returned.
      rawValue = val
    end

    -- If the value validation failed, but multiple values are allowed and the received type is a table,
    -- then the value is still valid if every item in the table passes validation.
    if err and options.multiple and traw == "table" then
      local convertedArray = {}
      local isWholeArrayValid = true
      for i, v in ipairs(rawValue) do
        local innerVal, innerErr = validateValue(v, options)
        if innerErr then
          validationError = string.format("Value #%i in '%s' is invalid: %s", i, self.name, innerErr)
          isWholeArrayValid = false
          break
        else
          convertedArray[i] = innerVal
        end
      end
      if isWholeArrayValid then
        validationError = nil
        rawValue = convertedArray
      end
    end

    -- Empty tables are not allowed if the value is required, even if the type check passes.
    if not validationError and traw == "table" and options.required then
      if not (addon:tlen(rawValue) > 0) then
        validationError = string.format("Required value '%s' must not be empty", self.name)
      end
    end

    -- Any parameter can supply additional validation checks in a custom OnValidate method
    -- But these checks are only run if the built-in validation checks have passed, so you can
    -- assume that any rawValue being passed to OnValidate has already been successfully validated
    if not validationError and self.OnValidate then
      local result, customErr = self:OnValidate(rawValue, options)
      if not result then
        validationError = customErr
      end
    end

    if validationError then
      error(validationError, 0)
    end

    return rawValue
  end,
  --- Wrapper for Validate that simply returns true or false if the value
  --- is valid (rather than throwing errors)
  ["IsValid"] = function(self, rawValue, options)
    local result, err = pcall(self.Validate, self, rawValue, options)
    -- if not result then addon.Logger:Debug("Validation error: %s", err) end
    return result
  end,
  ["Parse"] = function(self, rawValue, options)
    if rawValue == nil and self.defaultValue ~= nil then
      -- If the default value is used, bypass validate and parse
      rawValue = self.defaultValue
    else
      rawValue = self:Validate(rawValue, options)
      -- OnParse is skipped if the value is nil, but still valid (i.e. missing optional values)
      if rawValue ~= nil and self.OnParse then
        rawValue = self:OnParse(rawValue, options)
      end
    end
    return rawValue
  end,
  -- Functions that can be declared on any Parameter to further customize it
  ["OnValidate"] = nil,
  ["OnParse"] = nil,
}

--- Creates a new Parameter that is recognized by the QuestEngine.
--- A Parameter is a piece of data that can be validated as a specific type.
function addon.QuestEngine:NewParameter(name)
  local parameter = {
    name = name,
    logger = addon.QuestEngineLogger,
    options = {},
  }

  addon:ApplyMethods(parameter, methods)

  addon.QuestEngine:AddDefinition("parameters", name, parameter)
  return parameter
end