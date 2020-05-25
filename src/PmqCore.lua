local _, addon = ...
local print = addon.G.print

addon.ADDON_VERSION = "0.0.1"
addon.ADDON_BRANCH = "alpha"
addon.IsAddonLoaded = false

function addon.Ace:OnInitialize()
  addon:catch(function()

    -- addon.Logger:NewLogger("test")
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
-- Returns up to 4 values... not sure how to effectively make this dynamic
function addon:catch(fn, ...)
  local ok, result, r2, r3, r4 = pcall(fn, ...)
  if not(ok) then
    -- Uncomment this as an escape hatch to print errors if logging breaks
    -- print("Lua script error") if result then print(result) end
    addon.Logger:Error("Lua script error:", result)
  end
  return ok, result, r2, r3, r4
end

-- Defer code execution until the addon is fully loaded
local _onloadBuffer = {}
function addon:onload(fn)
  table.insert(_onloadBuffer, fn)
end

function addon:load()
  if _onloadBuffer == nil then return end
  for _, fn in pairs(_onloadBuffer) do
    local ok, err = pcall(fn)
    if not ok then
      print("[PMQ:onload] Startup error:", err)
    end
  end
  _onloadBuffer = nil
end

function addon:OnSaveDataLoaded(fn)
  if addon.SaveDataLoaded then
    -- If save data is already loaded, run the function now
    fn()
  elseif not _onloadBuffer then
    -- If the onload buffer has already been flushed, but save data is
    -- not loaded, then subscribe directly to the SaveDataLoaded event
    addon.AppEvents:Subscribe("SaveDataLoaded", fn)
  else
    -- Otherwise, subscribe to SaveDataLoaded only after the addon has
    -- fully loaded
    addon:onload(function()
      addon.AppEvents:Subscribe("SaveDataLoaded", fn)
    end)
  end
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