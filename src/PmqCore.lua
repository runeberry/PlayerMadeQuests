local _, addon = ...

addon.ADDON_VERSION = "0.0.1"
addon.ADDON_BRANCH = "alpha"
addon.IsAddonLoaded = false

function addon.Ace:OnInitialize()
  addon:catch(function()
    addon.Logger:NewLogger("test")
    addon.IsAddonLoaded = true
    addon:load()
    addon.SaveData:Init()
    addon.Logger:Info("PMQ Loaded")
  end)
end

function addon.Ace:OnEnable()

end

function addon.Ace:OnDisable()

end

function addon:GetVersion()
  if self.ADDON_BRANCH and self.ADDON_BRANCH ~= "" then
    return self.ADDON_VERSION.."-"..self.ADDON_BRANCH
  end

  return self.ADDON_VERSION
end

-- Runs the provided function, catching any Lua errors and logging them to console
-- Currently only returns a single result
function addon:catch(fn, ...)
  local ok, result = pcall(fn, ...)
  if not(ok) then
    -- Uncomment this as an escape hatch to print errors if logging breaks
    -- print("Lua script error") if result then print(result) end
    addon.Logger:Error("Lua script error")
    if result then
      addon.Logger:Error(result)
    end
  end
  return ok, result
end

-- Defer code execution until the addon is fully loaded
local _onloadBuffer = {}
function addon:onload(fn)
  table.insert(_onloadBuffer, fn)
end

function addon:load()
  if _onloadBuffer == nil then return end
  for _, fn in pairs(_onloadBuffer) do
    fn()
  end
  _onloadBuffer = nil
end

function addon:OnSaveDataLoaded(fn)
  addon:onload(function()
    addon.AppEvents:Subscribe("SaveDataLoaded", fn)
  end)
end

-- Place at the top of a file to help debugging in trace mode
local tracedFiles = {}
function addon:traceFile(filename)
  tracedFiles[filename] = true
end

function addon:assertFile(filename)
  if tracedFiles[filename] == nil then
    addon.Logger:Fatal("Expected file not loaded:", filename)
  end
end