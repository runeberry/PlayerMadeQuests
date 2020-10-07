local _, addon = ...
local Config = addon.Config

local menu = addon.MainMenu:NewMenuScreen("LoggingMenu")
local refreshTimer
local dataTable

local options = {
  colInfo = {
    {
      name = "Logger",
      align = "LEFT",
      width = { flexSize = 3, min = 80 },
    },
    {
      name = "# Logs",
      align = "RIGHT",
      width = { min = 80 }
    },
    {
      name = "Level",
      align = "RIGHT",
      width = { min = 60 }
    }
  },
  dataSource = function()
    local rows = {}
    local stats = addon:GetLogStats()
    for name, stat in pairs(stats) do
      local levelTextColored = addon:Colorize(addon.LogColors[stat.level], stat.levelname)
      local numLogs = string.format("%i/%i", stat.stats.printed, stat.stats.received)
      if stat.stats.printed == 0 then
        numLogs = addon:Colorize("grey", numLogs)
      end
      rows[#rows+1] = { name, numLogs, levelTextColored, stat.levelname }
    end
    table.sort(rows, function(a,b) return a[1] < b[1] end)
    return rows
  end,
  buttons = {
    {
      text = "Set Log Level",
      enabled = "Row",
      condition = function(row)
        return row[1] ~= "*"
      end,
      handler = function(row)
        addon.StaticPopups:Show("SetLogLevel", row[1], row[4]):OnYes(function()
          dataTable:RefreshData()
        end)
      end,
    },
    {
      text = "Reset All",
      opposite = true,
      enabled = "Always",
      handler = function()
        local logSettings = Config:GetValue("Logging")
        for k, v in pairs(logSettings) do
          addon:SetUserLogLevel(k, nil)
        end
        dataTable:RefreshData()
        addon.Logger:Warn("Log levels reset to PMQ defaults.")
      end,
    },
    {
      text = "Reset",
      opposite = true,
      enabled = "Row",
      handler = function(row)
        addon:SetUserLogLevel(row[1], nil)
        dataTable:RefreshData()
        addon.Logger:Warn("Reset log level for %s to PMQ default.", row[1])
      end,
    }
  },
}

function menu:Create(frame)
  local dtwb = addon.CustomWidgets:CreateWidget("DataTableWithButtons", frame, options)
  dataTable = dtwb:GetDataTable()

  frame.dataTable = dataTable
end

function menu:OnShowMenu(frame)
  frame.dataTable:RefreshData()
  if not refreshTimer then
    refreshTimer = addon.Ace:ScheduleRepeatingTimer(function()
      frame.dataTable:RefreshData()
    end, 5)
  end
end

function menu:OnLeaveMenu(frame)
  if refreshTimer then
    addon.Ace:CancelTimer(refreshTimer)
    refreshTimer = nil
  end
end