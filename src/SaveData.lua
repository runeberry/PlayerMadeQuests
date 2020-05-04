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

function addon.SaveData:Load(field, global)
  if not loaded then
    error("Cannot Load: SaveData not ready")
  end
  if global then
    return files.PMQGlobalCache[field]
  else
    return files.PMQCache[field]
  end
end

function addon.SaveData:LoadTable(field, global)
  local saved = self:Load(field, global)
  if saved == nil or type(saved) ~= "table" then
    saved = {}
    self:Save(field, saved, global)
  end
  return saved
end

function addon.SaveData:LoadString(field, global)
  local saved = self:Load(field, global)
  if saved == nil or type(saved) ~= "string" then
    saved = ""
    self:Save(field, saved, global)
  end
  return saved
end

function addon.SaveData:Save(field, value, global)
  if not loaded then
    error("Cannot Save: SaveData not ready")
  end
  if global then
    files.PMQGlobalCache[field] = value
  else
    files.PMQCache[field] = value
  end
end