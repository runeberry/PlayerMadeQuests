local _, addon = ...
local QuestArchive = addon.QuestArchive
local StaticPopups = addon.StaticPopups
local CreateFrame = addon.G.CreateFrame

local menu = addon.MainMenu:NewMenuScreen("archive")

local colinfo = {
  {
    name = "Quest",
    pwidth = 0.5,
    align = "LEFT"
  },
  {
    name = "Last Status",
    align = "RIGHT"
  }
}

local questArchiveRows = {}
local buttons = {
  {
    id = "info",
    text = "View Quest Info",
    anchor = "TOP",
    enabled = "Row"
  },
  {
    id = "share",
    text = "Share Quest",
    anchor = "TOP",
    enabled = "Row",
  },
  {
    id = "reset",
    text = "Reset Archive",
    anchor = "BOTTOM",
    enabled = "Always",
  },
  {
    id = "delete",
    text = "Delete Quest",
    anchor = "BOTTOM",
    enabled = "Row",
  },
}

local function setButtonState(row)
  for _, button in ipairs(buttons) do
    if button.enabled == "Always" then
      -- Button is always enabled, whether or not a row is selected
      button.frame:Enable()
    elseif button.enabled == "Row" then
      -- Button is only enabled when a row is selected
      if row then
        -- A row is selected
        if button.status then
          -- Button is only enabled on certain quest statuses
          if button.status[row[2]] then
            -- Quest is in a valid status for this button
            button.frame:Enable()
          else
            -- Quest is not in a valid status for this button
            button.frame:Disable()
          end
        else
          -- Button is enabled for all quest statuses
          button.frame:Enable()
        end
      else
        -- No row selected
        button.frame:Disable()
      end
    end
  end
end

local function getQuests()
  questArchiveRows = {}
  local quests = QuestArchive:FindAll()
  table.sort(quests, function(a, b) return a.questId < b.questId end)
  for _, quest in pairs(quests) do
    local row = { quest.name, quest.status, quest.questId }
    table.insert(questArchiveRows, row)
  end
  return questArchiveRows
end

function menu:Create(frame)
  local buttonPane = addon.CustomWidgets:CreateWidget("ButtonPane", frame, "LEFT", 120)

  local tablePane = CreateFrame("Frame", nil, frame)
  tablePane:SetPoint("TOPLEFT", buttonPane, "TOPRIGHT")
  tablePane:SetPoint("BOTTOMLEFT", buttonPane, "BOTTOMRIGHT")
  tablePane:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
  tablePane:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")

  local dataTable = addon.CustomWidgets:CreateWidget("DataTable", tablePane, colinfo, getQuests)
  dataTable:SubscribeToEvents("ArchiveDataLoaded", "ArchiveAdded", "ArchiveDeleted", "ArchiveDataReset")
  dataTable:OnRowSelected(setButtonState)
  dataTable:OnGetSelectedItem(function(row)
    return QuestArchive:FindByID(row[3])
  end)
  frame.dataTable = dataTable

  local function getRowQuest()
    local row = dataTable:GetSelectedRow()
    if not row or not row[3] then
      return
    end
    local quest = QuestArchive:FindByID(row[3])
    if not quest then
      addon.Logger:Error("No archived quest found with id", row[3])
      return
    end
    return quest
  end

  local handlers = {
    ["info"] = function()
      local quest = getRowQuest()
      if not quest then return end
      addon:ShowQuestInfoFrame(true, quest, nil, "TerminatedQuest")
      dataTable:ClearSelection()
    end,
    ["share"] = function()
      local row = dataTable:GetSelectedRow()
      QuestArchive:ShareQuest(row[3])
    end,
    ["delete"] = function()
      StaticPopups:Show("DeleteArchive", dataTable:GetSelectedItem())
    end,
    ["reset"] = function()
      StaticPopups:Show("ResetArchive", dataTable:GetSelectedItem())
    end,
  }

  for _, button in ipairs(buttons) do
    button.frame = buttonPane:AddButton(button.text, handlers[button.id], { anchor = button.anchor })
  end

  setButtonState()
end

function menu:OnShowMenu(frame)
  frame.dataTable:RefreshData()
  frame.dataTable:EnableUpdates(true)
  setButtonState(frame.dataTable:GetSelectedRow())
end

function menu:OnLeaveMenu(frame)
  frame.dataTable:EnableUpdates(false)
end