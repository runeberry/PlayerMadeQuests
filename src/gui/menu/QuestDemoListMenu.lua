local _, addon = ...
local QuestDemos = addon.QuestDemos
local CreateFrame = addon.G.CreateFrame

local menu = addon.MainMenu:NewMenuScreen("QuestDemoListMenu")

local dqRows = {}

local options = {
  colInfo = {
    {
      name = "Quest",
      pwidth = 0.7,
      align = "LEFT"
    },
    {
      name = "Faction",
      pwidth = 0.3,
      align = "RIGHT"
    }
  },
  dataSource = function()
    return dqRows
  end,
  buttons = {
    {
      text = "Start Quest",
      anchor = "TOP",
      enabled = "Row",
      handler = function(demo, dataTable)
        addon.QuestDemos:StartDemo(demo.demoId)
        dataTable:ClearSelection()
      end,
    },
    {
      text = "View Code",
      anchor = "TOP",
      enabled = "Row",
      handler = function(demo)
        addon.MainMenu:ShowMenuScreen("QuestDemoViewMenu", demo.demoId)
      end,
    },
    {
      text = "Copy to Drafts",
      anchor = "TOP",
      enabled = "Row",
      handler = function(demo)
        addon.StaticPopups:Show("RenameDemoCopy", demo)
      end,
    }
  },
}

function menu:Create(frame)
  for _, dq in pairs(QuestDemos:FindAll()) do
    table.insert(dqRows, { dq.demoName, dq.faction, dq.order, dq.demoId })
  end
  table.sort(dqRows, function(a, b) return a[3] < b[3] end)

  local dtwb = addon.CustomWidgets:CreateWidget("DataTableWithButtons", frame, options)
  dtwb:OnGetSelectedItem(function(row)
    return QuestDemos:FindByID(row[4])
  end)
  dtwb:GetDataTable():RefreshData()
end
