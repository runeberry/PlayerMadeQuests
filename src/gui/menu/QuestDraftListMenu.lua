local _, addon = ...
local QuestDrafts = addon.QuestDrafts
local date = addon.G.date

local menu = addon.MainMenu:NewMenuScreen("QuestDraftListMenu")

local draftRows = {}

local options = {
  colInfo = {
    {
      name = "Draft",
      width = { flexSize = 3 },
      align = "LEFT"
    },
    {
      name = "Last Modified",
      width = { flexSize = 2 },
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
      template = "plus",
      tooltipText = "New",
      enabled = "Always",
      handler = function()
        addon.MainMenu:ShowMenuScreen("QuestDraftEditMenu")
      end,
    },
    {
      template = "plus",
      tooltipText = "Edit",
      enabled = "Row",
      handler = function(draft)
        addon.MainMenu:ShowMenuScreen("QuestDraftEditMenu", draft.draftId)
      end,
    },
    {
      template = "!",
      tooltipText = "Start Quest",
      enabled = "Row",
      handler = function(draft, dataTable)
        addon.QuestDrafts:StartDraft(draft.draftId)
        dataTable:ClearSelection()
      end,
    },
    {
      template = "plus",
      tooltipText = "Share Quest",
      enabled = "Row",
      handler = function(draft)
        local ok, quest = addon.QuestDrafts:TryCompileDraft(draft.draftId)
        if not ok then
          addon.Logger:Warn("Your quest contains an error and cannot be shared: %s", quest)
          return
        end
        addon:ShareQuest(quest)
      end,
    },
    {
      template = "x",
      tooltipText = "Clear All",
      opposite = true,
      enabled = "Always",
      handler = function()
        addon.StaticPopups:Show("ResetDrafts")
      end,
    },
    {
      template = "x",
      tooltipText = "Delete",
      opposite = true,
      enabled = "Row",
      handler = function(draft)
        addon.StaticPopups:Show("DeleteDraft", draft.draftId, draft.draftName or "(untitled draft)")
      end,
    },
  },
}

function menu:Create(frame)
  local dtwb = addon.CustomWidgets:CreateWidget("DataTableWithIcons", frame, options)
  local dataTable = dtwb:GetDataTable()
  dataTable:SubscribeMethodToEvents("RefreshData", "DraftUpdated", "DraftDeleted", "DraftDataLoaded", "DraftDataReset")
  dataTable:SubscribeMethodToEvents("ClearSelection", "DraftDataLoaded", "DraftDeleted", "DraftDataReset")
  dataTable:OnGetSelectedItem(function(row)
    return QuestDrafts:FindByID(row[3])
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