local _, addon = ...
local QuestLog, QuestStatus = addon.QuestLog, addon.QuestStatus
local StaticPopups = addon.StaticPopups

local menu = addon.MainMenu:NewMenuScreen("QuestLogMenu")

local questLogRows = {}
local abandonableStatuses = {
  [QuestStatus.Active] = true,
  [QuestStatus.Failed] = true,
  [QuestStatus.Finished] = true,
}

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
    questLogRows = {}
    local quests = QuestLog:FindAll()
    table.sort(quests, function(a, b) return a.questId < b.questId end)
    for _, quest in pairs(quests) do
      local row = { quest.name, quest.status, quest.questId }
      table.insert(questLogRows, row)
    end
    return questLogRows
  end,
  buttons = {
    {
      text = "Toggle Window",
      anchor = "TOP",
      enabled = "Always",
      handler = function()
        addon.QuestLogFrame:ToggleShown()
      end
    },
    {
      text = "View Quest Info",
      anchor = "TOP",
      enabled = "Row",
      handler = function(quest, dataTable)
        addon.QuestInfoFrame:ShowQuest(quest)
        dataTable:ClearSelection()
      end,
    },
    {
      text = "Share Quest",
      anchor = "TOP",
      enabled = "Row",
      handler = function(quest)
        addon:ShareQuest(quest)
      end,
    },
    {
      text = "Abandon Quest",
      anchor = "TOP",
      enabled = "Row",
      condition = function(quest)
        return abandonableStatuses[quest.status]
      end,
      handler = function(quest)
        StaticPopups:Show("AbandonQuest", quest)
      end,
    },
    {
      text = "Clear All",
      anchor = "BOTTOM",
      enabled = "Always",
      handler = function(quest)
        StaticPopups:Show("ResetQuestLog", quest)
      end,
    },
    {
      text = "Delete",
      anchor = "BOTTOM",
      enabled = "Row",
      handler = function(quest)
        StaticPopups:Show("DeleteQuest", quest)
      end,
    },
    {
      text = "Archive Quest",
      anchor = "BOTTOM",
      enabled = "Row",
      handler = function(quest)
        StaticPopups:Show("ArchiveQuest", quest)
      end,
    },
  },
}

function menu:Create(frame)
  local dtwb = addon.CustomWidgets:CreateWidget("DataTableWithButtons", frame, options)
  local dataTable = dtwb:GetDataTable()
  dataTable:SubscribeMethodToEvents("RefreshData", "QuestDataLoaded", "QuestAdded", "QuestDeleted", "QuestStatusChanged", "QuestDataReset")
  dataTable:SubscribeMethodToEvents("ClearSelection", "QuestDataLoaded", "QuestDeleted", "QuestDataReset")
  dataTable:OnGetSelectedItem(function(row)
    return QuestLog:FindByID(row[3])
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