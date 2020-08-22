local _, addon = ...
local ConfigSource = addon.ConfigSource

local menu = addon.MainMenu:NewMenuScreen("ConfigMenu")

local configRows = {}

--- These config values will not be shown in this menu.
local configExclude = {
  VERSION = true,
  BRANCH = true,
}

local colorsBySource = {
  [ConfigSource.Default] = "grey",
  [ConfigSource.Global] = "blue",
  [ConfigSource.Character] = "yellow",
  [ConfigSource.Temporary] = "red",
}

local options = {
  colInfo = {
    {
      name = "Key",
      align = "LEFT",
      pwidth = 0.6,
    },
    {
      name = "Value",
      align = "RIGHT",
      pwidth = 0.4,
    },
  },
  dataSource = function()
    configRows = {}
    for _, item in pairs(addon.config) do
      if not configExclude[item.name] then
        local value = item.value
        if item.type == "table" then
          value = "table["..addon:tlen(value).."]"
        end
        if value == nil then
          addon.Logger:Warn("%s is nil", item.name)
        else
          value = addon:Colorize(colorsBySource[item.source], tostring(value))
          configRows[#configRows+1] = { item.name, value }
        end
      end
    end
    table.sort(configRows, function(a, b) return a[1] < b[1] end)
    return configRows
  end,
  buttons = {
    {
      text = "Edit",
      anchor = "TOP",
      enabled = "Row",
      handler = function(configItem)
        addon.StaticPopups:Show("EditConfigValue", configItem)
      end,
    },
    {
      text = "Reset All",
      anchor = "BOTTOM",
      enabled = "Always",
      handler = function()
        addon.StaticPopups:Show("ResetAllConfig")
      end,
    },
    {
      text = "Reset",
      anchor = "BOTTOM",
      enabled = "Row",
      handler = function(configItem)
        addon:SaveConfigValue(configItem.name, nil)
      end,
    },
  }
}

function menu:Create(frame)
  local dtwb = addon.CustomWidgets:CreateWidget("DataTableWithButtons", frame, options)
  local dataTable = dtwb:GetDataTable()
  dataTable:SubscribeMethodToEvents("RefreshData", "ConfigUpdated", "ConfigDataLoaded", "ConfigDataReset")
  dataTable:SubscribeMethodToEvents("ClearSelection", "ConfigDataLoaded", "ConfigDataReset")
  dataTable:OnGetSelectedItem(function(row)
    return addon.config[row[1]]
  end)

  frame.dataTable = dataTable
end

function menu:OnShowMenu(frame)
  frame.dataTable:RefreshData()
  frame.dataTable:EnableUpdates(true)
end

function menu:OnLeaveMenu(frame)
  frame.dataTable:EnableUpdates(false)
end