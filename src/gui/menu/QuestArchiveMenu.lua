local _, addon = ...
local QuestArchive = addon.QuestArchive
local StaticPopups = addon.StaticPopups

local menu = addon.MainMenu:NewMenuScreen("QuestArchiveMenu")

local questArchiveRows = {}

local options = {
  colInfo = {
    {
      name = "Quest",
      pwidth = 0.5,
      align = "LEFT"
    },
    {
      name = "Last Status",
      align = "RIGHT"
    }
  },
  dataSource = function()
    questArchiveRows = {}
    local quests = QuestArchive:FindAll()
    table.sort(quests, function(a, b) return a.questId < b.questId end)
    for _, quest in pairs(quests) do
      local row = { quest.name, quest.status, quest.questId }
      table.insert(questArchiveRows, row)
    end
    return questArchiveRows
  end,
  buttons = {
    {
      text = "View Quest Info",
      anchor = "TOP",
      enabled = "Row",
      handler = function(quest, dataTable)
        addon:ShowQuestInfoFrame(true, quest, nil, "TerminatedQuest")
        dataTable:ClearSelection()
      end,
    },
    {
      text = "Share Quest",
      anchor = "TOP",
      enabled = "Row",
      handler = function(quest)
        QuestArchive:ShareQuest(quest.questId)
      end,
    },
    {
      text = "Clear All",
      anchor = "BOTTOM",
      enabled = "Always",
      handler = function()
        StaticPopups:Show("ResetArchive")
      end,
    },
    {
      text = "Delete",
      anchor = "BOTTOM",
      enabled = "Row",
      handler = function(quest)
        StaticPopups:Show("DeleteArchive", quest)
      end,
    },
  },
}

function menu:Create(frame)
  local dtwb = addon.CustomWidgets:CreateWidget("DataTableWithButtons", frame, options)
  local dataTable = dtwb:GetDataTable()
  dataTable:SubscribeMethodToEvents("RefreshData", "ArchiveDataLoaded", "ArchiveAdded", "ArchiveDeleted", "ArchiveDataReset")
  dataTable:SubscribeMethodToEvents("ClearSelection", "ArchiveDataLoaded", "ArchiveDeleted", "ArchiveDataReset")
  dataTable:OnGetSelectedItem(function(row)
    return QuestArchive:FindByID(row[3])
  end)
  addon.AppEvents:Subscribe("ArchiveDataReset", function()
    dataTable:ClearSelection()
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