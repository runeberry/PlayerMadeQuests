local _, addon = ...
local QuestLog, QuestStatus = addon.QuestLog, addon.QuestStatus
local StaticPopups = addon.StaticPopups
local CreateFrame = addon.G.CreateFrame

local menu = addon.MainMenu:NewMenuScreen("QuestLogMenu")

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

local questLogRows = {}
local buttons = {
  {
    id = "toggle",
    text = "Toggle Window",
    anchor = "TOP",
    enabled = "Always",
  },
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
    id = "abandon",
    text = "Abandon Quest",
    anchor = "TOP",
    enabled = "Row",
    status = {
      [QuestStatus.Active] = true,
      [QuestStatus.Failed] = true,
      [QuestStatus.Finished] = true,
    }
  },
  {
    id = "reset",
    text = "Reset Quest Log",
    anchor = "BOTTOM",
    enabled = "Always",
  },
  {
    id = "delete",
    text = "Delete Quest",
    anchor = "BOTTOM",
    enabled = "Row",
  },
  {
    id = "archive",
    text = "Archive Quest",
    anchor = "BOTTOM",
    enabled = "Row",
    status = {
      [QuestStatus.Active] = true,
      [QuestStatus.Failed] = true,
      [QuestStatus.Abandoned] = true,
      [QuestStatus.Finished] = true,
      [QuestStatus.Completed] = true,
    }
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
  questLogRows = {}
  local quests = QuestLog:FindAll()
  table.sort(quests, function(a, b) return a.questId < b.questId end)
  for _, quest in pairs(quests) do
    local row = { quest.name, quest.status, quest.questId }
    table.insert(questLogRows, row)
  end
  return questLogRows
end

function menu:Create(frame)
  local buttonPane = addon.CustomWidgets:CreateWidget("ButtonPane", frame, "LEFT", 120)

  local tablePane = CreateFrame("Frame", nil, frame)
  tablePane:SetPoint("TOPLEFT", buttonPane, "TOPRIGHT")
  tablePane:SetPoint("BOTTOMLEFT", buttonPane, "BOTTOMRIGHT")
  tablePane:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
  tablePane:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")

  local dataTable = addon.CustomWidgets:CreateWidget("DataTable", tablePane, colinfo, getQuests)
  dataTable:SubscribeToEvents("QuestDataLoaded", "QuestAdded", "QuestDeleted", "QuestStatusChanged", "QuestDataReset")
  dataTable:OnRowSelected(setButtonState)
  dataTable:OnGetSelectedItem(function(row)
    return QuestLog:FindByID(row[3])
  end)
  frame.dataTable = dataTable

  local function getRowQuest()
    local row = dataTable:GetSelectedRow()
    if not row or not row[3] then
      return
    end
    local quest = QuestLog:FindByID(row[3])
    if not quest then
      addon.Logger:Error("No quest found with id: %s", row[3])
      return
    end
    return quest
  end

  local handlers = {
    ["toggle"] = function()
      addon.QuestLogFrame:ToggleShown()
    end,
    ["info"] = function()
      local quest = getRowQuest()
      if not quest then return end
      addon:ShowQuestInfoFrame(true, quest)
      dataTable:ClearSelection()
    end,
    ["share"] = function()
      local row = dataTable:GetSelectedRow()
      QuestLog:ShareQuest(row[3])
    end,
    ["abandon"] = function()
      StaticPopups:Show("AbandonQuest", dataTable:GetSelectedItem())
    end,
    ["archive"] = function()
      StaticPopups:Show("ArchiveQuest", dataTable:GetSelectedItem())
    end,
    ["delete"] = function()
      StaticPopups:Show("DeleteQuest", dataTable:GetSelectedItem())
    end,
    ["reset"] = function()
      StaticPopups:Show("ResetQuestLog", dataTable:GetSelectedItem())
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