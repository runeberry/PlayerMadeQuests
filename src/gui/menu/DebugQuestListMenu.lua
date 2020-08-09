local _, addon = ...
local DebugQuests = addon.DebugQuests
local strsplit = addon.G.strsplit

local menu = addon.MainMenu:NewMenuScreen("DebugQuestListMenu")

local dqRows = {}

local options = {
  colInfo = {
    {
      name = "Quest",
      align = "LEFT"
    },
  },
  dataSource = function()
    return dqRows
  end,
  buttons = {
    {
      text = "Start Quest",
      anchor = "TOP",
      enabled = "Row",
      handler = function(row, dataTable)
        DebugQuests:StartDebugQuest(row[2])
        dataTable:ClearSelection()
      end,
    },
    {
      text = "Print Code",
      anchor = "TOP",
      enabled = "Row",
      handler = function(row)
        local dq = DebugQuests:FindByID(row[2])
        local scriptLines = { strsplit("\n", dq.script) }
        addon.Logger:Info("Debug Quest Name: %s", dq.name)
        for _, line in ipairs(scriptLines) do
          addon.Logger:Info(line)
        end
      end,
    },
  },
}

function menu:Create(frame)
  for _, dq in pairs(DebugQuests:FindAll()) do
    table.insert(dqRows, { dq.name, dq.debugQuestId, dq.order })
  end
  table.sort(dqRows, function(a, b) return a[3] < b[3] end)

  local dtwb = addon.CustomWidgets:CreateWidget("DataTableWithButtons", frame, options)
  local dataTable = dtwb:GetDataTable()
  dataTable:RefreshData()
end