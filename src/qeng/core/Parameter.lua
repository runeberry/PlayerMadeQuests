local _, addon = ...
local assertf, errorf = addon.assertf, addon.errorf
local logger = addon.QuestEngineLogger -- todo: reappropriate this logger

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
    if options then
      options = addon:MergeTable(self.options, options)
    else
      options = self.options
    end

    -- First, check if the value is nil. If the value is not required, we can safely return now, there is nothing to validate.
    -- But if the value is required, then nil is immediately invalid.
    if rawValue == nil then
      if options.required then
        errorf("Required value '%s' is missing", self.name)
      end
      return
    end

    local validationError = string.format("Unknown validation error for '%s'", self.name)
    local isTypeValid = true
    local traw = type(rawValue)

    -- Then, check the list of allowed types. The user input value should match one of those types.
    if options.type then
      isTypeValid = false
      for _, t in ipairs(options.type) do
        if traw == t then
          isTypeValid = true
          break
        end
      end
      if not isTypeValid then
        local types = table.concat(options.type, " or ")
        validationError = string.format("Expected type %s for '%s', but got %s", types, self.name, traw)
      end
    end

    -- If the type check failed, but multiple values are allowed and the received type is a table,
    -- then the value is still valid if every item in the table matches one of the allowed types.
    if not isTypeValid and options.multiple and traw == "table" then
      local isWholeArrayValid = true
      for _, v in ipairs(rawValue) do
        local isThisItemValid = false
        for _, t in ipairs(options.type) do
          if type(v) == t then
            isThisItemValid = true
            break
          end
        end
        if not isThisItemValid then
          isWholeArrayValid = false
          break
        end
      end
      isTypeValid = isWholeArrayValid
      if not isTypeValid then
        local types = table.concat(options.type, " or ")
        validationError = string.format("All items in '%s' must be of type %s", self.name, types)
      end
    end

    -- Empty tables are not allowed if the value is required, even if the type check passes.
    if isTypeValid and traw == "table" and options.required then
      if not (addon:tlen(rawValue) > 0) then
        isTypeValid = false
        validationError = string.format("Required value '%s' must not be empty", self.name)
      end
    end

    -- Finally, before failing validation for an invalid type, try to convert the value to an
    -- allowed type. If this type conversion succeeds, then we'll still allow the value and
    -- return the converted value from this method.
    if not isTypeValid and options.type then
      for _, t in ipairs(options.type) do
        local ok, converted = pcall(addon.ConvertValue, addon, rawValue, t)
        if ok then
          -- Quit attempting after the first successful conversion
          rawValue = converted
          isTypeValid = true
          break
        end
      end
    end

    -- Any parameter can supply additional validation checks in a custom OnValidate method
    -- But these checks are only run if the built-in validation checks have passed, so you can
    -- assume that any rawValue being passed to OnValidate has already been successfully validated
    if isTypeValid and self.OnValidate then
      local result, err = self:OnValidate(rawValue, options)
      if not result then
        isTypeValid = false
        validationError = err
      end
    end

    if not isTypeValid then
      error(validationError)
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
    if rawValue == nil and self.defaultValue then
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
    logger = logger,
    options = {},
  }

  for fname, fn in pairs(methods) do
    parameter[fname] = fn
  end

  addon.QuestEngine:AddDefinition("parameters", name, parameter)
  return parameter
end