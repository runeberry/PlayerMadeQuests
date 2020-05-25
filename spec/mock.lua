local mock = {}

local functionMocks = {}

local function afmt(condition, str, ...)
  assert(condition, string.format(str, ...))
end

local function efmt(str, ...)
  error(string.format(str, ...))
end

local mockMethods = {
  ["AssertCalled"] = function(self, times)
    if times then
      afmt(self.called == times,
        "Expected function %s to be called %i times, but it was called %i times.",
        self.name, times, self.called)
    else
      afmt(self.called > 0,
        "Expected function %s to be called at least once, but it was never called.",
        self.name)
    end
  end,
  ["AssertNotCalled"] = function(self)
    afmt(self.called == 0,
      "Expected function %s not to be called, but it was called %i times.",
      self.name, self.called)
  end,
  ["AssertCalledWith"] = function(self, ...)
    local vals = { ... }
    if #vals == 0 then
      efmt("AssertCalledWith must supply at least one expected arg")
    end
    for _, args in pairs(self.calledArgs) do
      local found = true
      for i, val in pairs(vals) do
        if args[i] ~= val then
          found = false
          break
        end
      end
      if found then
        return
      end
    end
    efmt("Expected function %s to be called with args: %s",
      self.name, table.concat(vals, ","))
  end,
  ["AssertCalledWhen"] = function(self, condition)
    for _, args in pairs(self.calledArgs) do
      if condition(table.unpack(args)) then
        return
      end
    end
    error("Expected function to be called with a condition, but it was not")
  end,
  ["Reset"] = function(self)
    self.called = 0
    self.calledArgs = {}
  end,
  ["SetHandler"] = function(self, fn)
    self.handler = fn
  end,
  ["SetReturns"] = function(self, ...)
    self.defaultReturns = { ... }
  end,
  ["SetReturnsWhen"] = function(self, condition, ...)
    table.insert(self.conditionalReturns, {
      value = { ... },
      condition = condition
    })
  end,
  ["ClearReturns"] = function(self)
    self.defaultReturns = nil
    self.conditionalReturns = {}
  end
}

function mock:Returns(...)
  return {
    returns = {
      value = { ... }
    }
  }
end

function mock:ReturnsWhen(condition, ...)
  return {
    returns = {
      value = { ... },
      condition = condition
    }
  }
end

function mock:Handler(fn)
  return {
    handler = fn
  }
end

local function createMockWrapper(m)
  return function(...)
    m.called = m.called + 1
    table.insert(m.calledArgs, { ... })
    for _, ret in pairs(m.conditionalReturns) do
      if ret.condition(...) then
        return table.unpack(ret.value)
      end
    end
    if m.handler then
      return m.handler(...)
    elseif m.defaultReturns then
      return table.unpack(m.defaultReturns)
    end
  end
end

function mock:NewMock(...)
  local m = {
    name = "",
    called = 0,
    calledArgs = {},
    handler = nil,
    defaultReturns = nil,
    conditionalReturns = {}
  }

  for name, fn in pairs(mockMethods) do
    m[name] = fn
  end

  for _, arg in pairs({ ... }) do
    if type(arg) == "string" then
      m.name = arg
    elseif arg.returns then
      if not arg.returns.condition then
        m:SetReturns(table.unpack(arg.returns.value))
      else
        m:SetReturnsWhen(arg.returns.condition, table.unpack(arg.returns.value))
      end
    elseif arg.handler then
      m:SetHandler(arg.handler)
    end
  end

  local fn = createMockWrapper(m)
  functionMocks[fn] = m
  return fn, m
end

function mock:GetMock(fn)
  assert(type(fn) == "function", "Expected a function arg for GetMock")
  assert(functionMocks[fn], "No mock registered for function")
  return functionMocks[fn]
end

return mock