local _, addon = ...
local QuestDrafts = addon.QuestDrafts
local date = addon.G.date

local menu = addon.MainMenu:NewMenuScreen("QuestDraftListMenu")

local draftRows = {}

local options = {
  colInfo = {
    {
      name = "Draft",
      pwidth = 0.6,
      align = "LEFT"
    },
    {
      name = "Last Modified",
      align = "RIGHT"
    }
  },
  dataSource = function()
    draftRows = {}
    local drafts = QuestDrafts:FindAll()
    table.sort(drafts, function(a, b) return a.draftId < b.draftId end)
    for _, draft in pairs(drafts) do
      local draftName = draft.draftName or "(untitled draft)"
      local row = { draftName, date("%x %X", draft.ud), draft.draftId }
      table.insert(draftRows, row)
    end
    return draftRows
  end,
  buttons = {
    {
      text = "New",
      anchor = "TOP",
      enabled = "Always",
      handler = function()
        addon.MainMenu:ShowMenuScreen("QuestDraftEditMenu")
      end,
    },
    {
      text = "Edit",
      anchor = "TOP",
      enabled = "Row",
      handler = function(draft)
        addon.MainMenu:ShowMenuScreen("QuestDraftEditMenu", draft.draftId)
      end,
    },
    {
      text = "Delete",
      anchor = "TOP",
      enabled = "Row",
      handler = function(draft)
        addon.StaticPopups:Show("DeleteDraft", draft.draftId, draft.name)
      end,
    },
    {
      text = "Start Quest",
      anchor = "TOP",
      enabled = "Row",
      handler = function(draft, dataTable)
        addon.QuestDrafts:StartDraft(draft.draftId)
        dataTable:ClearSelection()
      end,
    },
    {
      text = "Share Quest",
      anchor = "TOP",
      enabled = "Row",
      handler = function(draft)
        addon.QuestDrafts:ShareDraft(draft.draftId)
      end,
    },
  },
}

function menu:Create(frame)
  local dtwb = addon.CustomWidgets:CreateWidget("DataTableWithButtons", frame, options)
  dtwb:SubscribeToEvents("DraftUpdated", "DraftDeleted", "DraftDataLoaded")
  dtwb:OnGetSelectedItem(function(row)
    return QuestDrafts:FindByID(row[3])
  end)
  frame.dataTable = dtwb:GetDataTable()
end

function menu:OnShowMenu(frame)
  frame.dataTable:RefreshData()
  frame.dataTable:EnableUpdates(true)
end

function menu:OnLeaveMenu(frame)
  frame.dataTable:EnableUpdates(false)
end