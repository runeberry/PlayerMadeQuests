local _, addon = ...
local logger = addon.Logger:NewLogger("SaveData")

local SavedVariables = {
  PMQCache = false,
  PMQGlobalCache = false
}

addon.SaveData = {}
addon.PlayerSettings = nil
addon.GlobalSettings = nil
addon.SaveDataLoaded = false

local function getSaveTable(global)
  if global then
    return SavedVariables.PMQGlobalCache
  else
    return SavedVariables.PMQCache
  end
end

function addon.SaveData:Init()
  if addon.SaveDataLoaded then return end
  for varname in pairs(SavedVariables) do
    local saved = _G[varname]
    if not saved then
      saved = {}
      _G[varname] = saved
    end
    SavedVariables[varname] = saved
  end
  addon.SaveDataLoaded = true
  logger:Debug("SaveData loaded")

  -- These are such frequently used tables, just make them easily accessible
  addon.PlayerSettings = self:LoadTable("Settings")
  addon.GlobalSettings = self:LoadTable("Settings", true)

  addon.AppEvents:Publish("SaveDataLoaded")
end

-- Returns the value of the specified field from SavedVariables
-- If the value is a table, then a copy of the saved table is returned
function addon.SaveData:Load(field, global)
  assert(addon.SaveDataLoaded, "Failed to Load field"..field..": SaveData not loaded")
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
  assert(addon.SaveDataLoaded, "Failed to Save field"..field..": SaveData not loaded")
  getSaveTable(global)[field] = value
  logger:Trace("SaveData field saved: %s", field)
end

-- Saves nil to the specified field in SavedVariables
function addon.SaveData:Clear(field, global)
  assert(addon.SaveDataLoaded, "Failed to Clear field "..field..": SaveData not loaded")
  getSaveTable(global)[field] = nil
  logger:Debug("SaveData field cleared: %s", field)
end

-- Resets all SavedVariables
function addon.SaveData:ClearAll(global)
  assert(addon.SaveDataLoaded, "Failed to ClearAll: SaveData not loaded")
  local t = getSaveTable(global)
  for k, _ in pairs(t) do
    t[k] = nil
  end
  logger:Debug("SaveData cleared")
end