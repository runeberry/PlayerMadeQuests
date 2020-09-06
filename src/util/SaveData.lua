local _, addon = ...
local logger = addon.Logger:NewLogger("SaveData")

local SavedVariables = {
  PMQCache = false,
  PMQGlobalCache = false
}

local isSaveDataLoaded = false

addon.SaveData = {}

local function getSaveTable(global)
  if global then
    return SavedVariables.PMQGlobalCache
  else
    return SavedVariables.PMQCache
  end
end

--- Called as part of the addon lifecycle.
function addon.SaveData:Init()
  for varname in pairs(SavedVariables) do
    local saved = _G[varname]
    if not saved then
      -- No SaveData means this is the first run of the addon
      addon.IsFirstRun = true
      saved = {}
      _G[varname] = saved
    end
    SavedVariables[varname] = saved
  end
  isSaveDataLoaded = true
  logger:Debug("SaveData loaded")

  addon.AppEvents:Publish("SaveDataLoaded")
end

-- Returns the value of the specified field from SavedVariables
-- If the value is a table, then a copy of the saved table is returned
function addon.SaveData:Load(field, global)
  assert(isSaveDataLoaded, "Failed to Load field"..field..": SaveData not loaded")
  local value = getSaveTable(global)[field]
  logger:Trace("SaveData field loaded: %s", field)
  return value
end

-- Same as Load, but ensures that the returned value is a table
-- If the value is not a table, then a new empty table is returned
function addon.SaveData:LoadTable(field, global)
  local saved = self:Load(field, global)
  if saved == nil or type(saved) ~= "table" then
    saved = {}
    self:Save(field, saved, global)
  end
  return saved
end

-- Same as Load, but ensures that the returned value is a string
-- If the value is not a string, then an empty string is returned
function addon.SaveData:LoadString(field, global)
  local saved = self:Load(field, global)
  if saved == nil or type(saved) ~= "string" then
    saved = ""
    self:Save(field, saved, global)
  end
  return saved
end

-- Saves the value to the specified field in SavedVariables
function addon.SaveData:Save(field, value, global)
  assert(isSaveDataLoaded, "Failed to Save field"..field..": SaveData not loaded")
  getSaveTable(global)[field] = value
  logger:Trace("SaveData field saved: %s", field)
end

-- Saves nil to the specified field in SavedVariables
function addon.SaveData:Clear(field, global)
  assert(isSaveDataLoaded, "Failed to Clear field "..field..": SaveData not loaded")
  getSaveTable(global)[field] = nil
  logger:Debug("SaveData field cleared: %s", field)
end

-- Resets all SavedVariables
function addon.SaveData:ClearAll(global)
  assert(isSaveDataLoaded, "Failed to ClearAll: SaveData not loaded")
  local t = getSaveTable(global)
  for k, _ in pairs(t) do
    t[k] = nil
  end
  logger:Debug("SaveData cleared")
end