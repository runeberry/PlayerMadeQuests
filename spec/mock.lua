local mock = {}

local functionMocks = {}

local function assertf(condition, str, ...)
  assert(condition, string.format(str, ...))
end

local function errorf(str, ...)
  error(string.format(str, ...))
end

local mockMethods = {
  -- Assertion methods
  ["AssertCalled"] = function(self, times)
    if times then
      assertf(self.called == times,
        "Expected function %s to be called %i times, but it was called %i times.",
        self.name, times, self.called)
    else
      assertf(self.called > 0,
        "Expected function %s to be called at least once, but it was never called.",
        self.name)
    end
  end,
  ["AssertNotCalled"] = function(self)
    assertf(self.called == 0,
      "Expected function %s not to be called, but it was called %i times.",
      self.name, self.called)
  end,
  ["AssertCalledWith"] = function(self, ...)
    local expectedArgs = { ... }
    if #expectedArgs == 0 then
      errorf("AssertCalledWith must supply at least one expected arg")
    end
    for _, calledArgs in pairs(self.calledArgs) do
      local found = true
      for i, val in pairs(expectedArgs) do
        if calledArgs[i] ~= val then
          found = false
          break
        end
      end
      if found then
        return
      end
    end
    errorf("Expected function %s to be called with args: %s",
      self.name, table.concat(expectedArgs, ","))
  end,
  ["AssertCalledWhen"] = function(self, condition)
    for _, args in pairs(self.calledArgs) do
      if condition(table.unpack(args)) then
        return
      end
    end
    error("Expected function to be called with a condition, but it was not")
  end,
  -- Setup methods
  ["SetFunction"] = function(self, fn)
    self.fn = fn
  end,
  ["SetReturns"] = function(self, ...)
    self.returns = { ... }
  end,
  ["SetReturnsWhen"] = function(self, condition, ...)
    table.insert(self.conditionalReturns, {
      condition = condition,
      returns = { ... },
    })
  end,
  ["Reset"] = function(self)
    self:ClearCalls()
    self:ClearReturns()
  end,
  ["ClearCalls"] = function(self)
    self.called = 0
    self.calledArgs = {}
  end,
  ["ClearReturns"] = function(self)
    self.returns = nil
    self.conditionalReturns = {}
  end
}

local function buildMockFunction(fn, name)
  local context = functionMocks[fn]
  if context then return context end -- function has already been mockMethods

  context = {
    name = name or "Anonymous function", -- For logging and assertions
    fn = nil, -- The original function that was mocked, assigned below
    called = 0, -- Number of times the function was called
    calledArgs = {}, -- An array of the arrays of args the function was called with
    conditionalReturns = {}, -- Return values to return when specified conditions are met
    returns = nil, -- Overridden return values when no conditions are met
  }

  context.fn = function(...)
    context.called = context.called + 1
    context.calledArgs[#context.calledArgs+1] = { ... }
    for _, cr in ipairs(context.conditionalReturns) do
      if cr.condition(...) then
        return table.unpack(cr.returns)
      end
    end
    if context.returns ~= nil then
      return table.unpack(context.returns)
    end
    if context.name == "CreateFrame" then
      print(context.name, ":", table.unpack(fn(...)))
    end
    return fn(...)
  end

  functionMocks[context.fn] = context
  return context.fn
end

local function buildMockObject(object, circ)
  circ = circ or {}
  local copy = {}
  circ[object] = copy -- Ensure the provided table won't get copied twice
  for k, v in pairs(object) do
    if type(v) == "table" then
      if circ[v] then
        -- Use the same copy for each instance of the same inner table
        copy[k] = circ[v]
      else
        copy[k] = buildMockObject(v, circ)
      end
    elseif type(v) == "function" then
      -- Functions are wrapped with a context that tracks how they were called
      copy[k] = buildMockFunction(v, k)
    else
      -- All other value types (strings, numbers, etc.) are left as-is
      copy[k] = v
    end
  end
  return copy
end

----------------------
-- Public functions --
----------------------

function mock:NewMock(object)
  assert(type(object) == "table", "Mocked object must be a table, but was "..type(object))
  return buildMockObject(object)
end

function mock:GetFunctionMock(fn)
  assert(type(fn) == "function", "Expected a function arg for GetFunctionMock, but got "..type(fn))
  local functionMock = functionMocks[fn]
  assert(functionMock, "No mock registered for function")

  -- Methods aren't assigned until GetFunctionMock is called; this is a performance optimization
  for name, method in pairs(mockMethods) do
    functionMock[name] = method
  end

  return functionMock
end

return mock