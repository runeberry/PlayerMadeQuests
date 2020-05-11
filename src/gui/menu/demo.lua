local _, addon = ...
local CreateFrame = addon.G.CreateFrame

local menu = addon.MainMenu:NewMenuScreen([[demo]], "Demo Quests")

local colinfo = {
  {
    name = "Objective",
    width = 100,
    align = "LEFT"
  },
  {
    name = "Progress",
    width = 50,
    align = "CENTER"
  },
  {
    name = "Goal",
    width = 50,
    align = "CENTER"
  }
}

local testdata = {
  { "table start"}
}

local function getDemoQuests(obj)
  if obj ~= nil then
    table.insert(testdata, { obj.name, obj.progress, obj.goal })
  end
  return testdata
end

function menu:Create(parent)
  local frame = CreateFrame("Frame", nil, parent)
  frame:SetAllPoints(true)
  frame:Hide()

  local dataTable = addon.CustomWidgets:CreateWidget("DataTable", frame, colinfo, getDemoQuests)
  dataTable:SubscribeToEvents("ObjectiveUpdated")

  frame.dataTable = dataTable

  return frame
end

function menu:OnShow(frame)
  frame.dataTable:EnableUpdates(true)
  frame.dataTable:RefreshData()
end

function menu:OnHide(frame)
  frame.dataTable:EnableUpdates(false)
end
