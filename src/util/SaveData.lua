local _, addon = ...

local SavedVariables = {
  PMQCache = false,
  PMQGlobalCache = false
}

addon.SaveData = {}
addon.PlayerSettings = nil
addon.GlobalSettings = nil
addon.SaveDataLoaded = false

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

  -- These are such frequently used tables, just make them easily accessible
  addon.PlayerSettings = self:LoadTable("Settings")
  addon.GlobalSettings = self:LoadTable("Settings", true)

  addon.AppEvents:Publish("SaveDataLoaded")
end

-- Returns the value of the specified field from SavedVariables
-- If the value is a table, then a copy of the saved table is returned
function addon.SaveData:Load(field, global)
  if not addon.SaveDataLoaded then
    error("Cannot Load: SaveData not ready")
  end
  local value
  if global then
    value = SavedVariables.PMQGlobalCache[field]
  else
    value = SavedVariables.PMQCache[field]
  end
  -- addon.Logger:Debug("SaveData loaded. ("..field..")")
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
  if not addon.SaveDataLoaded then
    error("Cannot Save: SaveData not ready")
  end
  if global then
    SavedVariables.PMQGlobalCache[field] = value
  else
    SavedVariables.PMQCache[field] = value
  end
  -- addon.Logger:Debug("SaveData saved. ("..field..")")
end