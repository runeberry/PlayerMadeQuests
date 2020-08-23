local _, addon = ...
local logger = addon.Logger:NewLogger("Config")

--- The settings that are ultimately used in game will be stored here
addon.Config = {
  items = {}
}

local ConfigSource = {
  Default = "default",
  Global = "global",
  Character = "character",
  Temporary = "temporary",
}
addon.ConfigSource = ConfigSource

local isConfigLoaded = false

--- Internal function for setting a config value.
--- @return any value - returns the type-converted value if it was set successfully, or nil if there was an error
--- @return string source - the resolved source of the updated value, or an error message if it was not set successfully
local function setValue(key, value, source)
  local item = addon.Config.items[key]
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

  return item.value, item.source
end

--- Called as part of the addon lifecycle.
function addon.Config:Init()
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

      local existing = addon.Config.items[k]
      if not existing then
        existing = {
          name = k,
          type = tvalue,
        }
        addon.Config.items[k] = existing
      end

      existing.value = addon:ConvertValue(v, existing.type)
      existing.source = s.source
    end
  end

  isConfigLoaded = true
end

function addon.Config:GetConfig()
  return addon.Config.items
end

--- Gets the current value of a config item
--- @param key string - the key to lookup
--- @return any value - the value at this key
--- @return string source - one of ConfigSource
function addon.Config:GetValue(key)
  assert(isConfigLoaded, "Failed to GetConfigValue: Config is not loaded")
  assert(type(key) == "string", "Failed to GetConfigValue: a string key must be provided")

  local item = addon.Config.items[key]
  if not item then
    logger:Warn("Failed to GetConfigValue: %s is not a known config item", key)
    return
  end

  return item.value, item.source
end

--- Sets the value of a config item. Does not persist between reloads.
--- @param key string - the key to assign this value to
--- @param value any - the value to set
function addon.Config:SetValue(key, value)
  assert(isConfigLoaded, "Failed to SetConfigValue: Config is not loaded")
  assert(type(key) == "string", "Failed to SetConfigValue: a string key must be provided")

  local v, src = setValue(key, value, ConfigSource.Temporary)
  if v == nil then
    logger:Warn("Failed to SetConfigValue: %s", src)
    return
  end

  addon.AppEvents:Publish("ConfigUpdated", key, v)
end

--- Sets the value of a config item and writes it to the player's SavedVariables
--- so that it will persist between reloads.
--- @param key string
--- @param value any
--- @param global boolean - true to save globally (same for all characters), false or nil to save to character
function addon.Config:SaveValue(key, value, global)
  assert(isConfigLoaded, "Failed to SaveConfigValue: Config is not loaded")
  assert(type(key) == "string", "Failed to SaveConfigValue: a string key must be provided")

  local source
  if global then source = ConfigSource.Global else source = ConfigSource.Character end
  local v, src = setValue(key, value, source)
  if v == nil then
    logger:Warn("Failed to SaveConfigValue: %s", src)
    return
  end

  local savedSettings = addon.SaveData:LoadTable("Settings", global)
  if src == ConfigSource.Default then
    -- If the default value was set, then erase the player's saved value
    savedSettings[key] = nil
  elseif src == source then
    -- Otherwise, save the updated value to the player's SavedVariables
    savedSettings[key] = v
  end
  addon.SaveData:Save("Settings", savedSettings, global)

  addon.AppEvents:Publish("ConfigUpdated", key, v)
end

--- Resets all config values to PMQ's defaults. Erases SavedVariable data as well.
function addon.Config:ResetAll()
  assert(isConfigLoaded, "Failed to SetConfigValue: Config is not loaded")

  for k in pairs(addon.Config.items) do
    setValue(k, nil)
  end

  addon.SaveData:Save("Settings", nil)
  addon.SaveData:Save("Settings", nil, true)

  addon.AppEvents:Publish("ConfigDataReset")
end
