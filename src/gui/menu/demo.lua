local _, addon = ...
local QuestDemos = addon.QuestDemos
local CreateFrame = addon.G.CreateFrame

local menu = addon.MainMenu:NewMenuScreen("demo")

local colinfo = {
  {
    name = "Quest",
    pwidth = 0.5,
    align = "LEFT"
  },
  {
    name = "Demo ID",
    pwidth = 0.5,
    align = "RIGHT"
  }
}

local dqRows = {}
local buttons = {}

local function getDemoQuests()
  return dqRows
end

local function setButtonState(row)
  if row then
    buttons[1]:Enable()
    buttons[2]:Enable()
    buttons[3]:Enable()
  else
    buttons[1]:Disable()
    buttons[2]:Disable()
    buttons[3]:Disable()
  end
end

function menu:Create(frame)
  for _, dq in pairs(QuestDemos:FindAll()) do
    table.insert(dqRows, { dq.parameters.name, dq.demoId, dq.order })
  end
  table.sort(dqRows, function(a, b) return a[3] < b[3] end)

  local buttonPane = addon.CustomWidgets:CreateWidget("ButtonPane", frame, "LEFT", 120)

  local tablePane = CreateFrame("Frame", nil, frame)
  tablePane:SetPoint("TOPLEFT", buttonPane, "TOPRIGHT")
  tablePane:SetPoint("BOTTOMLEFT", buttonPane, "BOTTOMRIGHT")
  tablePane:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
  tablePane:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")

  local dataTable = addon.CustomWidgets:CreateWidget("DataTable", tablePane, colinfo, getDemoQuests)
  dataTable:RefreshData()
  dataTable:OnRowSelected(setButtonState)
  frame.dataTable = dataTable

  local acceptQuest = function()
    local row = dataTable:GetSelectedRow()
    if not row or not row[2] then
      return
    end
    local ok, quest = addon.QuestDemos:CompileDemo(row[2])
    if not ok then
      addon.Logger:Error("Failed to accept demo quest:", quest)
      return
    end
    addon.AppEvents:Publish("QuestInvite", quest)
    dataTable:ClearSelection()
  end

  local viewCode = function()
    local selectedRow = dataTable:GetSelectedRow()
    if not selectedRow then return end
    local demoId = selectedRow[2]
    addon.MainMenu:ShowMenuScreen("demo-view", demoId)
  end

  local copyToDrafts = function()
    local row = dataTable:GetSelectedRow()
    if not row or not row[2] then
      return
    end
    addon.QuestDemos:CopyToDrafts(row[2])
    addon.Logger:Info("Demo quest copied to drafts.")
  end

  buttons[1] = buttonPane:AddButton("Accept Quest", acceptQuest)
  buttons[2] = buttonPane:AddButton("View Code", viewCode)
  buttons[3] = buttonPane:AddButton("Copy to Drafts", copyToDrafts)

  setButtonState(nil)
end

function menu:OnShow(frame)
  setButtonState(frame.dataTable:GetSelectedRow())
end