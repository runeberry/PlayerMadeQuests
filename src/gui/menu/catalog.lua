local _, addon = ...
local QuestCatalog = addon.QuestCatalog
local CreateFrame = addon.G.CreateFrame

local menu = addon.MainMenu:NewMenuScreen("catalog")

local colinfo = {
  {
    name = "Quest",
    pwidth = 0.5,
    align = "LEFT"
  },
  {
    name = "Status",
    align = "RIGHT"
  }
}

local catalogRows = {}
local buttons = {}

-- local function setButtonState(row)
--   if row then
--     buttons[2]:Enable()
--     buttons[3]:Enable()
--     buttons[4]:Enable()
--     buttons[5]:Enable()
--   else
--     buttons[2]:Disable()
--     buttons[3]:Disable()
--     buttons[4]:Disable()
--     buttons[5]:Disable()
--   end
-- end

local function getCatalog()
  catalogRows = {}
  local catalog = QuestCatalog:FindAll()
  table.sort(catalog, function(a, b) return a.questId < b.questId end)
  for _, item in pairs(catalog) do
    local row = { item.quest.name, item.status, item.questId }
    table.insert(catalogRows, row)
  end
  return catalogRows
end

function menu:Create(frame)
  local buttonPane = addon.CustomWidgets:CreateWidget("ButtonPane", frame, "LEFT", 120)

  local tablePane = CreateFrame("Frame", nil, frame)
  tablePane:SetPoint("TOPLEFT", buttonPane, "TOPRIGHT")
  tablePane:SetPoint("BOTTOMLEFT", buttonPane, "BOTTOMRIGHT")
  tablePane:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
  tablePane:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")

  local dataTable = addon.CustomWidgets:CreateWidget("DataTable", tablePane, colinfo, getCatalog)
  dataTable:SubscribeToEvents("CatalogItemUpdated", "CatalogItemDeleted", "CatalogItemDataLoaded")
  -- dataTable:OnRowSelected(setButtonState)
  frame.dataTable = dataTable

  local confirmCatalogDelete = addon.StaticPopups:NewPopup("ConfirmCatalogDelete")
  confirmCatalogDelete:SetText(function()
    local selectedRow = dataTable:GetSelectedRow()
    if not selectedRow then return end
    return "Are you sure you want to delete "..selectedRow[1].."?"
  end)
  confirmCatalogDelete:SetYesButton("OK", function()
    local row = dataTable:GetSelectedRow()
    if not row then return end
    QuestCatalog:Delete(row[3])
    addon.Logger:Info("Catalog item deleted:", row[1])
  end)
  confirmCatalogDelete:SetNoButton("Cancel")

  local deleteCatalogItem = function()
    local selectedRow = dataTable:GetSelectedRow()
    if not selectedRow then return end
    confirmCatalogDelete:Show()
  end

  local startQuest = function()
    local row = dataTable:GetSelectedRow()
    if not row then return end
    QuestCatalog:StartFromCatalog(row[3])
    dataTable:ClearSelection()
  end

  local shareQuest = function()
    local row = dataTable:GetSelectedRow()
    if not row then return end
    QuestCatalog:ShareFromCatalog(row[3])
  end

  buttons[1] = buttonPane:AddButton("Start Quest", startQuest)
  buttons[2] = buttonPane:AddButton("Share Quest", shareQuest)
  buttons[3] = buttonPane:AddButton("Delete", deleteCatalogItem)

  -- setButtonState(nil)
end

function menu:OnShowMenu(frame)
  frame.dataTable:RefreshData()
  frame.dataTable:EnableUpdates(true)
  -- setButtonState(frame.dataTable:GetSelectedRow())
end

function menu:OnLeaveMenu(frame)
  frame.dataTable:EnableUpdates(false)
end