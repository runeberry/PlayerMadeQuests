local _, addon = ...
local assertf, asserttype = addon.assertf, addon.asserttype

addon.HookType = {
  PreHook = "PreHook",
  PostHook = "PostHook",
}

local function noOp() end

local function logError(...)
  if addon.Logger then addon.Logger:Error(...) end
end

local function setMethod(obj, fname, fn, force)
  if type(fname) ~= "string" or type(fn) ~= "function" then return end

  if not force and obj[fname] ~= nil then
    return logError("setMethod: '%s' is already a method on this object", fname)
  end

  obj[fname] = fn
end

local function hookMethod(obj, fname, fn, hookType)
  if type(fname) ~= "string" or type(fn) ~= "function" then return end

  local method = obj[fname]

  if method ~= nil and type(method) ~= "function" then
    return logError("hookMethod: Cannot hook '%s' because it is not a function (type: %s)", fname, type(method))
  end

  if not method then
    method = noOp
  end

  local hookedMethod

  if hookType == addon.HookType.PreHook then
    hookedMethod = function(...)
      fn(...)
      method(...)
    end
  elseif hookType == addon.HookType.PostHook then
    hookedMethod = function(...)
      method(...)
      fn(...)
    end
  end

  obj[fname] = hookedMethod
end

--- Copies a table of methods to an object
function addon:ApplyMethods(obj, methods, force)
  asserttype(obj, "table", "obj", "ApplyMethods")
  asserttype(methods, "table", "methods", "ApplyMethods")

  for fname, fn in pairs(methods) do
    setMethod(obj, fname, fn, force)
  end
end

function addon:HookMethods(obj, methods, hookType)
  asserttype(obj, "table", "obj", "HookMethods")
  asserttype(methods, "table", "methods", "HookMethods")

  hookType = hookType or addon.HookType.PostHook
  assertf(addon.HookType[hookType], "HookMethods: '%s' is not a recognized hookType", hookType)

  for fname, fn in pairs(methods) do
    hookMethod(obj, fname, fn, hookType)
  end
end