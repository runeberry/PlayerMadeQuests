local _, addon = ...
local QuestDemos = addon.QuestDemos
local CreateFrame = addon.G.CreateFrame

local menu = addon.MainMenu:NewMenuScreen([[demo]], "Demo Quests", true)

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

local function getDemoQuests()
  return dqRows
end

function menu:Create(parent)
  local frame = CreateFrame("Frame", nil, parent)
  frame:SetAllPoints(true)
  frame:Hide()

  for _, dq in pairs(QuestDemos:FindAll()) do
    table.insert(dqRows, { dq.name, dq.id })
  end

  local buttonPane = addon.CustomWidgets:CreateWidget("ButtonPane", frame, "LEFT", 120)

  local tablePane = CreateFrame("Frame", nil, frame)
  tablePane:SetPoint("TOPLEFT", buttonPane, "TOPRIGHT")
  tablePane:SetPoint("BOTTOMLEFT", buttonPane, "BOTTOMRIGHT")
  tablePane:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
  tablePane:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")

  local dataTable = addon.CustomWidgets:CreateWidget("DataTable", tablePane, colinfo, getDemoQuests)
  dataTable:RefreshData()
  -- frame.dataTable = dataTable

  local acceptQuest = function()
    local row = dataTable:GetSelectedRow()
    if not row or not row[2] then
      return
    end
    addon.Logger:Table(row)
    addon.QuestLog:AcceptDemo(row[2])
    dataTable:ClearSelection()
  end

  local viewCode = function()
    local selectedRow = dataTable:GetSelectedRow()
    if not selectedRow then return end
    local demoId = selectedRow[2]
    addon.MainMenu:Show("demo-view", demoId)
  end

  buttonPane:AddButton("Accept Quest", acceptQuest)
  buttonPane:AddButton("View Code", viewCode)
  buttonPane:AddButton("Copy to Drafts")

  return frame
end

-- function menu:OnShow(frame)
--   -- frame.dataTable:EnableUpdates(true)
--   -- frame.dataTable:RefreshData()
-- end

-- function menu:OnHide(frame)
--   -- frame.dataTable:EnableUpdates(false)
-- end
