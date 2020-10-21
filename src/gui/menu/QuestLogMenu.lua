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
      template = "copy",
      tooltipText = "Quest Log Window",
      tooltipDescription = "Show or hide the quest log window",
      enabled = "Always",
      handler = function()
        addon.QuestLogFrame:ToggleShown()
      end
    },
    {
      template = "!",
      tooltipText = "View Quest Info",
      enabled = "Row",
      handler = function(quest, dataTable)
        addon.QuestInfoFrame:ShowQuest(quest)
        dataTable:ClearSelection()
      end,
    },
    {
      template = "plus",
      tooltipText = "Share Quest",
      enabled = "Row",
      handler = function(quest)
        addon:ShareQuest(quest)
      end,
    },
    {
      template = "x",
      tooltipText = "Abandon Quest",
      enabled = "Row",
      condition = function(quest)
        return abandonableStatuses[quest.status]
      end,
      handler = function(quest)
        StaticPopups:Show("AbandonQuest", quest)
      end,
    },
    {
      template = "x",
      tooltipText = "Clear All",
      opposite = true,
      enabled = "Always",
      handler = function(quest)
        StaticPopups:Show("ResetQuestLog", quest)
      end,
    },
    {
      template = "x",
      tooltipText = "Delete",
      opposite = true,
      enabled = "Row",
      handler = function(quest)
        StaticPopups:Show("DeleteQuest", quest)
      end,
    },
    {
      template = "x",
      tooltipText = "Archive Quest",
      opposite = true,
      enabled = "Row",
      handler = function(quest)
        StaticPopups:Show("ArchiveQuest", quest)
      end,
    },
  },
}

function menu:Create(frame)
  local dtwb = addon.CustomWidgets:CreateWidget("DataTableWithIcons", frame, options)
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