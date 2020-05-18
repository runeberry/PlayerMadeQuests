local _, addon = ...
local QuestDrafts = addon.QuestDrafts
local CreateFrame = addon.G.CreateFrame

local menu = addon.MainMenu:NewMenuScreen([[drafts]], "My Questography", true)

local colinfo = {
  {
    name = "Quest",
    pwidth = 0.5,
    align = "LEFT"
  },
  {
    name = "Version",
    alight = "RIGHT"
  },
  {
    name = "Status",
    align = "RIGHT"
  }
}

local draftRows = {}

local function getDrafts()
  draftRows = {}
  local drafts = QuestDrafts:GetDrafts()
  for _, draft in pairs(drafts) do
    local row = { draft.name, draft.version, draft.status, draft.id }
    table.insert(draftRows, row)
  end
  return draftRows
end

function menu:Create(parent)
  local frame = CreateFrame("Frame", nil, parent)
  frame:SetAllPoints(true)
  frame:Hide()

  local buttonPane = addon.CustomWidgets:CreateWidget("ButtonPane", frame, "LEFT", 120)

  local tablePane = CreateFrame("Frame", nil, frame)
  tablePane:SetPoint("TOPLEFT", buttonPane, "TOPRIGHT")
  tablePane:SetPoint("BOTTOMLEFT", buttonPane, "BOTTOMRIGHT")
  tablePane:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
  tablePane:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")

  local dataTable = addon.CustomWidgets:CreateWidget("DataTable", tablePane, colinfo, getDrafts)
  dataTable:SubscribeToEvents("DraftCreated", "DraftDeleted")
  frame.dataTable = dataTable

  local newDraft = function()
    QuestDrafts:NewDraft("Draft")
    -- addon.MainMenu:Show("draft-view")
  end

  local editDraft = function()
    local selectedRow = dataTable:GetSelectedRow()
    if not selectedRow then return end
    local draftId = selectedRow[4]
    addon.Logger:Info(draftId)
    -- addon.MainMenu:Show("draft-view", draftId)
  end

  local confirmDraftDelete = addon.StaticPopups:NewPopup("ConfirmDraftDelete")
  confirmDraftDelete:SetText(function()
    local selectedRow = dataTable:GetSelectedRow()
    if not selectedRow then return end
    return "Are you sure you want to delete "..selectedRow[1].."?"
  end)
  confirmDraftDelete:SetYesButton("OK", function()
    local selectedRow = dataTable:GetSelectedRow()
    if not selectedRow then return end
    local draftId = selectedRow[4]
    QuestDrafts:DeleteDraft(draftId)
    addon.Logger:Info("Draft deleted:", selectedRow[1])
  end)
  confirmDraftDelete:SetNoButton("Cancel")

  local deleteDraft = function()
    local selectedRow = dataTable:GetSelectedRow()
    if not selectedRow then return end
    confirmDraftDelete:Show()
  end

  local acceptQuest = function()
    local row = dataTable:GetSelectedRow()
    if not row or not row[4] then
      return
    end
    addon.QuestLog:AcceptDraft(row[4])
    dataTable:ClearSelection()
  end

  local shareQuest = function()
    addon.Logger:Warn("Share Quest feature not yet implemented!")
  end

  buttonPane:AddButton("New", newDraft)
  buttonPane:AddButton("Edit", editDraft)
  buttonPane:AddButton("Delete", deleteDraft)
  buttonPane:AddButton("Accept Quest", acceptQuest)
  buttonPane:AddButton("Share Quest", shareQuest)

  return frame
end

function menu:OnShow(frame)
  frame.dataTable:RefreshData()
  frame.dataTable:EnableUpdates(true)
end

function menu:OnHide(frame)
  frame.dataTable:EnableUpdates(false)
end