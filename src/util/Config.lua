local _, addon = ...
local logger = addon.Logger:NewLogger("Config")

--- The settings that are ultimately used in game will be stored here
addon.config = {}

local ConfigSource = {
  Default = "default",
  Global = "global",
  Character = "character",
  Temporary = "temporary",
}
addon.ConfigSource = ConfigSource

--- Internal function for setting a config value.
--- @return boolean value - returns the type-converted value if it was set successfully, or nil if there was an error
--- @return string err - an error message if ok was false
local function setValue(key, value, source)
  local item = addon.config[key]
  if not item then
    return nil, key.." is not a known config item"
  end

  if value == nil then
    local defaultValue = addon.defaultSettings[key]
    if defaultValue == nil then
      return nil, "attempted to set nil, but "..key.." does not have a default value"
    end
    item.value = defaultValue
    item.source = ConfigSource.Default
  else
    if source == nil then
      return nil, "no config source was provided"
    end
    item.value = addon:ConvertValue(value, item.type)
    item.source = source
  end

  return item.value
end

--- Gets the current value of a config item
--- @param key string - the key to lookup
--- @return any value - the value at this key
--- @return string source - one of ConfigSource
function addon:GetConfigValue(key)
  assert(addon.ConfigLoaded, "Failed to GetConfigValue: Config is not loaded")
  assert(type(key) == "string", "Failed to GetConfigValue: a string key must be provided")

  local item = addon.config[key]
  if not item then
    logger:Warn("Failed to GetConfigValue: %s is not a known config item", key)
    return
  end

  return item.value, item.source
end

--- Sets the value of a config item. Does not persist between reloads.
--- @param key string - the key to assign this value to
--- @param value any - the value to set
function addon:SetConfigValue(key, value)
  assert(addon.ConfigLoaded, "Failed to SetConfigValue: Config is not loaded")
  assert(type(key) == "string", "Failed to SetConfigValue: a string key must be provided")

  local v, err = setValue(key, value, ConfigSource.Temporary)
  if err then
    logger:Warn("Failed to SetConfigValue: %s", err)
    return
  end

  addon.AppEvents:Publish("ConfigUpdated", key, v)
end

--- Sets the value of a config item and writes it to the player's SavedVariables
--- so that it will persist between reloads.
--- @param key string
--- @param value any
--- @param global boolean - true to save globally (same for all characters), false or nil to save to character
function addon:SaveConfigValue(key, value, global)
  assert(addon.ConfigLoaded, "Failed to SaveConfigValue: Config is not loaded")
  assert(type(key) == "string", "Failed to SaveConfigValue: a string key must be provided")

  local source
  if global then source = ConfigSource.Global else source = ConfigSource.Character end
  local v, err = setValue(key, value, source)
  if err then
    logger:Warn("Failed to SaveConfigValue: %s", err)
    return
  end

  local savedSettings = addon.SaveData:LoadTable("Settings", global)
  savedSettings[key] = v
  addon.SaveData:Save("Settings", savedSettings, global)

  addon.AppEvents:Publish("ConfigUpdated", key, v)
end

--- Resets all config values to PMQ's defaults. Erases SavedVariable data as well.
function addon:ResetAllConfig()
  assert(addon.ConfigLoaded, "Failed to SetConfigValue: Config is not loaded")

  for k in pairs(addon.config) do
    setValue(k, nil)
  end

  addon.SaveData:Save("Settings", nil)
  addon.SaveData:Save("Settings", nil, true)

  addon.AppEvents:Publish("ConfigDataReset")
end

addon:OnSaveDataLoaded(function()
  local settingsLoadOrder = {
    {
      source = ConfigSource.Default,
      data = addon.defaultSettings
    },
    {
      source = ConfigSource.Global,
      data = addon.SaveData:LoadTable("Settings", true)
    },
    {
      source = ConfigSource.Character,
      data = addon.SaveData:LoadTable("Settings")
    },
  }

  for _, s in ipairs(settingsLoadOrder) do
    for k, v in pairs(s.data) do
      local tvalue = type(v)

      local existing = addon.config[k]
      if not existing then
        existing = {
          name = k,
          type = tvalue,
        }
        addon.config[k] = existing
      end

      existing.value = addon:ConvertValue(v, existing.type)
      existing.source = s.source
    end
  end

  addon.ConfigLoaded = true
  addon.AppEvents:Publish("ConfigDataLoaded")
end)