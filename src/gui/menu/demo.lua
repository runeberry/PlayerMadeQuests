local _, addon = ...
local QuestDemos = addon.QuestDemos
local CreateFrame = addon.G.CreateFrame

local menu = addon.MainMenu:NewMenuScreen([[demo]], "Demo Quests")

local colinfo = {
  {
    name = "QuestID",
    width = 200,
    align = "LEFT"
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

  for _, dq in pairs(QuestDemos:GetDemos()) do
    table.insert(dqRows, { dq.id })
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
    if not row or not row[1] then
      return
    end
    local demoId = row[1]
    local demo = addon.QuestDemos:GetDemoByID(demoId)
    if not demo then
      -- addon.Logger:Error("Error: no demo quest exists with id:", args[2])
      return
    end
    local parameters = addon.QuestEngine:Compile(demo.script)
    local quest = addon.QuestEngine:NewQuest(parameters)
    quest:StartTracking()
    addon.QuestEngine:Save()
    dataTable:ClearSelection()
  end

  buttonPane:AddButton("Accept Quest", acceptQuest)
  buttonPane:AddButton("View Code")
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
