local _, addon = ...
local Config, ConfigSource = addon.Config, addon.ConfigSource
local CreateFrame = addon.G.CreateFrame

local menu = addon.MainMenu:NewMenuScreen("ConfigMenu")

local configRows = {}

--- These config values will not be shown in this menu.
local configExclude = {
  CHARSET = true,
  URL_DISCORD = true,
  URL_GITHUB = true,
  URL_WIKI = true,
  FrameData = true,
  Logging = true,
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
      width = { flexSize = 3 },
    },
    {
      name = "Value",
      align = "RIGHT",
      width = { flexSize = 2 },
    },
  },
  dataSource = function()
    configRows = {}
    for _, item in pairs(Config:GetConfig()) do
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
      enabled = "Row",
      handler = function(configItem)
        addon.StaticPopups:Show("EditConfigValue", configItem)
      end,
    },
    {
      text = "Toggle",
      enabled = "Row",
      condition = function(configItem)
        return configItem.type == "boolean"
      end,
      handler = function(configItem)
        configItem.value = not configItem.value
        local v = Config:SaveValue(configItem.name, configItem.value)
        if v ~= nil then
          addon.Logger:Warn("Config value updated: %s = %s", configItem.name, tostring(v))
        end
      end,
    },
    {
      text = "Reset All",
      opposite = true,
      enabled = "Always",
      handler = function()
        addon.StaticPopups:Show("ResetAllConfig")
      end,
    },
    {
      text = "Reset",
      opposite = true,
      enabled = "Row",
      handler = function(configItem)
        addon.Config:SaveValue(configItem.name, nil)
      end,
    },
  }
}

function menu:Create(frame)
  local textinfo = {
    static = true,
    styles = addon.DefaultArticleTextStyle,
    text = {
      {
        style = "page-header",
        text = "Configuration",
      },
      {
        style = "default",
        text = "Use this menu to change settings within PMQ.\nYou must "..addon:Colorize("orange", "/reload").." for changes to take effect."

      },
      {
        style = "default",
        text = "For more information, check out the Configuration page on the PMQ wiki:\n"..
               "        "..addon:Colorize("blue", addon.Config:GetValue("URL_WIKI").."/wiki/Configuration")
      }
    }
  }

  local article = addon.CustomWidgets:CreateWidget("ArticleText", frame, textinfo)
  article:ClearAllPoints(true)
  article:SetPoint("TOPLEFT", frame, "TOPLEFT")
  article:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
  article:SetHeight(90)

  local dtFrame = CreateFrame("Frame", nil, frame)
  dtFrame:SetPoint("TOPLEFT", article, "BOTTOMLEFT")
  dtFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")

  local dtwb = addon.CustomWidgets:CreateWidget("DataTableWithButtons", dtFrame, options)
  local dataTable = dtwb:GetDataTable()
  dataTable:SubscribeMethodToEvents("RefreshData", "ConfigUpdated", "ConfigDataLoaded", "ConfigDataReset")
  dataTable:SubscribeMethodToEvents("ClearSelection", "ConfigDataLoaded", "ConfigDataReset")
  dataTable:OnGetSelectedItem(function(row)
    return Config:GetConfig()[row[1]]
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