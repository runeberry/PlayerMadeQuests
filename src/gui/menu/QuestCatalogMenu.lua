local _, addon = ...
local QuestCatalog = addon.QuestCatalog

local menu = addon.MainMenu:NewMenuScreen("QuestCatalogMenu")

local catalogRows = {}

local options = {
  colInfo = {
    {
      name = "Quest",
      pwidth = 0.5,
      align = "LEFT"
    },
    {
      name = "Status",
      align = "RIGHT"
    }
  },
  dataSource = function()
    catalogRows = {}
    local catalog = QuestCatalog:FindAll()
    table.sort(catalog, function(a, b) return a.questId < b.questId end)
    for _, item in pairs(catalog) do
      local row = { item.quest.name, item.status, item.questId }
      table.insert(catalogRows, row)
    end
    return catalogRows
  end,
  buttons = {
    {
      text = "Start Quest",
      anchor = "TOP",
      enabled = "Row",
      handler = function(catalogItem, dataTable)
        QuestCatalog:StartFromCatalog(catalogItem.questId)
        dataTable:ClearSelection()
      end,
    },
    {
      text = "Share Quest",
      anchor = "TOP",
      enabled = "Row",
      handler = function(catalogItem)
        QuestCatalog:ShareFromCatalog(catalogItem.questId)
      end,
    },
    {
      text = "Delete",
      anchor = "TOP",
      enabled = "Row",
      handler = function(catalogItem)
        addon.StaticPopups:Show("DeleteCatalogItem", catalogItem)
      end,
    },
  }
}

function menu:Create(frame)
  local dtwb = addon.CustomWidgets:CreateWidget("DataTableWithButtons", frame, options)
  dtwb:SubscribeToEvents("CatalogItemUpdated", "CatalogItemDeleted", "CatalogItemDataLoaded")
  dtwb:OnGetSelectedItem(function(row)
    return QuestCatalog:FindByID(row[3])
  end)

  frame.dataTable = dtwb._dataTable
end

function menu:OnShowMenu(frame)
  frame.dataTable:RefreshData()
  frame.dataTable:EnableUpdates(true)
end

function menu:OnLeaveMenu(frame)
  frame.dataTable:EnableUpdates(false)
end