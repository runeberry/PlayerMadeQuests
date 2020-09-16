local _, addon = ...
local QuestCatalog = addon.QuestCatalog

local menu = addon.MainMenu:NewMenuScreen("QuestCatalogMenu")

local catalogRows = {}

local options = {
  colInfo = {
    {
      name = "Quest",
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
        addon.QuestInfoFrame:ShowQuest(catalogItem.quest)
        dataTable:ClearSelection()
      end,
    },
    {
      text = "Share Quest",
      anchor = "TOP",
      enabled = "Row",
      handler = function(catalogItem)
        addon:ShareQuest(catalogItem.quest)
      end,
    },
    {
      text = "Clear All",
      anchor = "BOTTOM",
      enabled = "Always",
      handler = function()
        addon.StaticPopups:Show("ResetCatalog")
      end,
    },
    {
      text = "Delete",
      anchor = "BOTTOM",
      enabled = "Row",
      handler = function(catalogItem)
        addon.StaticPopups:Show("DeleteCatalogItem", catalogItem)
      end,
    },
  }
}

function menu:Create(frame)
  local dtwb = addon.CustomWidgets:CreateWidget("DataTableWithButtons", frame, options)
  local dataTable = dtwb:GetDataTable()
  dataTable:SubscribeMethodToEvents("RefreshData", "CatalogItemUpdated", "CatalogItemDeleted", "CatalogItemDataLoaded", "CatalogItemDataReset")
  dataTable:SubscribeMethodToEvents("ClearSelection", "CatalogDataLoaded", "CatalogItemDeleted", "CatalogDataReset")
  dataTable:OnGetSelectedItem(function(row)
    return QuestCatalog:FindByID(row[3])
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