local _, addon = ...
local AceGUI = addon.AceGUI
local QuestLog, QuestStatus, localizer = addon.QuestLog, addon.QuestStatus, addon.QuestScriptLocalizer
local CreateFrame = addon.G.CreateFrame
local QuestDrafts = addon.QuestDrafts

addon.PositionFinderFrame = nil -- Built at end of file

local frameOptions = {
  styleOptions = {
    text = "Location Finder"
  },
  resizable = {
    minWidth = 400,
    minHeight = 250,
  },
  position = {
    p1 = "RIGHT",
    p2 = "RIGHT",
    x = -100,
    y = 0,
    w = 250,
    h = 300,
    shown = true
  }
}

local options = {
  colInfo = {
    {
      name = "Draft",
      pwidth = 0.6,
      align = "LEFT"
    },
    {
      name = "Last Modified",
      align = "RIGHT"
    }
  },
  dataSource = function()
    -- draftRows = {}
    -- local drafts = QuestDrafts:FindAll()
    -- table.sort(drafts, function(a, b) return a.draftId < b.draftId end)
    -- for _, draft in pairs(drafts) do
    --   local draftName = draft.draftName or "(untitled draft)"
    --   local row = { draftName, date("%x %X", draft.ud), draft.draftId }
    --   table.insert(draftRows, row)
    -- end
    -- return draftRows
    return {}
  end,
  buttons = {
    {
      text = "New",
      anchor = "TOP",
      enabled = "Always",
      handler = function()
        addon.MainMenu:ShowMenuScreen("QuestDraftEditMenu")
      end,
    },
    {
      text = "Update",
      anchor = "TOP",
      enabled = "Row",
      handler = function(draft)
        addon.MainMenu:ShowMenuScreen("QuestDraftEditMenu", draft.draftId)
      end,
    },
    {
      text = "Rename",
      anchor = "TOP",
      enabled = "Row",
      handler = function(draft, dataTable)
        addon.QuestDrafts:StartDraft(draft.draftId)
        dataTable:ClearSelection()
      end,
    },
    {
      text = "Delete",
      anchor = "TOP",
      enabled = "Row",
      handler = function(draft)
        addon.QuestDrafts:ShareDraft(draft.draftId)
      end,
    },
    {
      text = "Delete All",
      anchor = "TOP",
      enabled = "Row",
      handler = function()
        addon.StaticPopups:Show("ResetDrafts")
      end,
    },
  },
}


local function buildPositionFinderFrame()
  local frame = addon.CustomWidgets:CreateWidget("ToolWindowPopout", "LocationFinderFrame", frameOptions)
  local contentFrame = frame:GetContentFrame()
  local text = "PLAYER_POSITION"
  local playerLocationText = contentFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
  playerLocationText:SetText(text)
  playerLocationText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT")
  playerLocationText:SetHeight(30)

  local dtwb = addon.CustomWidgets:CreateWidget("DataTableWithButtons", contentFrame, options)
  dtwb:ClearAllPoints()
  dtwb:SetPoint("TOPLEFT", playerLocationText, "BOTTOMLEFT")
  dtwb:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT")
  local dataTable = dtwb:GetDataTable()
  dataTable:SubscribeMethodToEvents("RefreshData", "LocationUpdated", "LocationDeleted", "LocationDataLoaded", "LocationDataReset")
  dataTable:SubscribeMethodToEvents("ClearSelection", "LocationDataLoaded", "LocationDeleted", "LocationDataReset")
  dataTable:OnGetSelectedItem(function(row)
    return QuestDrafts:FindByID(row[3])
  end)
  addon:StartPollingLocation("location-frame")
  addon.AppEvents:Subscribe("PlayerLocationChanged", function(loc)
    local location = addon:GetPlayerLocation()
    if location.subZone == "" then
      text = location.zone .." ("..string.format("%.2f", location.x).. ", ".. string.format("%.2f", location.y)..")"
    else
      text = location.subZone.. ", "..location.zone .." ("..string.format("%.2f", location.x).. ", ".. string.format("%.2f", location.y)..")"
    end

    playerLocationText:SetText(text)
  end)

  return frame
end

addon:OnSaveDataLoaded(function()
  if addon.AVOID_BUILDING_UI then return end
  addon.PositionFinderFrame = buildPositionFinderFrame()
end)