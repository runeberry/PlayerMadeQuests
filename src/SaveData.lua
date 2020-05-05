local _, addon = ...
addon:traceFile("SaveData.lua")

local loaded = false
local files = {
  PMQCache = false,
  PMQGlobalCache = false
}

addon.SaveData = {}

function addon.SaveData:Init()
  -- Load all "files" from global variables
  for varname in pairs(files) do
    local saved = _G[varname]
    if not saved then
      saved = {}
      _G[varname] = saved
    end
    files[varname] = saved
  end
  loaded = true
end

-- Returns the value of the specified field from SavedVariables
-- If the value is a table, then a copy of the saved table is returned
function addon.SaveData:Load(field, global)
  if not loaded then
    error("Cannot Load: SaveData not ready")
  end
  local value
  if global then
    value = files.PMQGlobalCache[field]
  else
    value = files.PMQCache[field]
  end
  if type(value) == "table" then
    value = addon:CopyTable(value)
  end
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
-- If the value is a table, it is copied and cleaned before saving
function addon.SaveData:Save(field, value, global)
  if not loaded then
    error("Cannot Save: SaveData not ready")
  end
  if type(value) == "table" then
    value = addon:CopyTable(value)
    addon:CleanTable(value)
  end
  if global then
    files.PMQGlobalCache[field] = value
  else
    files.PMQCache[field] = value
  end
end