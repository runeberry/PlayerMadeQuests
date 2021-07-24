local _, addon = ...

addon.VERSION = 600
addon.BRANCH = "beta"
addon.TIMESTAMP = 1627148271

function addon.Ace:OnInitialize()
  addon:OnAddonReady(function()
    addon.Logger:Info("PlayerMadeQuests %s loaded. Main menu: %s", addon:GetVersionText(), addon:Colorize("orange", "/pmq"))
  end)
  addon:catch(function()
    addon.Lifecycle:Init()
  end)
end

-- Runs the provided function, catching any Lua errors and logging them to console
-- Returns up to 4 values... not sure how to effectively make this dynamic
function addon:catch(fn, ...)
  local ok, result, r2, r3, r4 = pcall(fn, ...)
  if not(ok) then
    -- Uncomment this as an escape hatch to print errors if logging breaks
    -- print("Lua script error") if result then print(result) end
    addon.Logger:Fatal("Lua script error: %s", result)
  end
  return ok, result, r2, r3, r4
end

--- Wrapper for error() that uses string.format for error messages
function addon.errorf(msg, ...)
  error(string.format(msg, ...), 2)
end

--- Wrapper for assert() that uses string.format for error messages
function addon.assertf(bool, msg, ...)
  if not bool then
    error(string.format(msg, ...), 2)
  end
end

--- Asserts that the provided value is of the specified type
function addon.asserttype(value, vartype, varname, fname, errLevel)
  if type(value) ~= vartype then
    local message
    if value == nil then
      message = string.format("%s: %s must not be nil",
        fname or "Function", varname or "value")
    else
      message = string.format("%s: expected %s to be type %s, but got type %s",
        fname or "Function", varname or "value", vartype, type(value))
    end
    error(message, (errLevel or 1) + 1)
  end
end