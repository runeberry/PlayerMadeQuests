local _, addon = ...
local QuestDrafts = addon.QuestDrafts
local CreateFrame = addon.G.CreateFrame

local menu = addon.MainMenu:NewMenuScreen("drafts")

local colinfo = {
  {
    name = "Quest",
    pwidth = 0.5,
    align = "LEFT"
  },
  {
    name = "Version",
    align = "RIGHT"
  },
  {
    name = "Status",
    align = "RIGHT"
  }
}

local draftRows = {}
local buttons = {}

local function setButtonState(row)
  if row then
    buttons[2]:Enable()
    buttons[3]:Enable()
    buttons[4]:Enable()
    buttons[5]:Enable()
  else
    buttons[2]:Disable()
    buttons[3]:Disable()
    buttons[4]:Disable()
    buttons[5]:Disable()
  end
end

local function getDrafts()
  draftRows = {}
  local drafts = QuestDrafts:FindAll()
  table.sort(drafts, function(a, b) return a.draftId < b.draftId end)
  for _, draft in pairs(drafts) do
    local draftName = draft.parameters.name or "(untitled draft)"
    local row = { draftName, draft.version, draft.status, draft.draftId }
    table.insert(draftRows, row)
  end
  return draftRows
end

function menu:Create(frame)
  local buttonPane = addon.CustomWidgets:CreateWidget("ButtonPane", frame, "LEFT", 120)

  local tablePane = CreateFrame("Frame", nil, frame)
  tablePane:SetPoint("TOPLEFT", buttonPane, "TOPRIGHT")
  tablePane:SetPoint("BOTTOMLEFT", buttonPane, "BOTTOMRIGHT")
  tablePane:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
  tablePane:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")

  local dataTable = addon.CustomWidgets:CreateWidget("DataTable", tablePane, colinfo, getDrafts)
  dataTable:SubscribeToEvents("DraftUpdated", "DraftDeleted", "DraftDataLoaded")
  dataTable:OnRowSelected(setButtonState)
  frame.dataTable = dataTable

  local newDraft = function()
    addon.MainMenu:ShowMenuScreen("draft-view")
  end

  local editDraft = function()
    local selectedRow = dataTable:GetSelectedRow()
    if not selectedRow then return end
    local draftId = selectedRow[4]
    addon.MainMenu:ShowMenuScreen("draft-view", draftId)
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
    QuestDrafts:Delete(draftId)
    addon.Logger:Info("Draft deleted:", selectedRow[1])
  end)
  confirmDraftDelete:SetNoButton("Cancel")

  local deleteDraft = function()
    local selectedRow = dataTable:GetSelectedRow()
    if not selectedRow then return end
    confirmDraftDelete:Show()
  end

  local startQuest = function()
    local row = dataTable:GetSelectedRow()
    if not row then return end
    addon.QuestDrafts:StartDraft(row[4])
    dataTable:ClearSelection()
  end

  local shareQuest = function()
    local row = dataTable:GetSelectedRow()
    if not row then return end
    addon.QuestDrafts:ShareDraft(row[4])
  end

  buttons[1] = buttonPane:AddButton("New", newDraft)
  buttons[2] = buttonPane:AddButton("Edit", editDraft)
  buttons[3] = buttonPane:AddButton("Delete", deleteDraft)
  buttons[4] = buttonPane:AddButton("Start Quest", startQuest)
  buttons[5] = buttonPane:AddButton("Share Quest", shareQuest)

  setButtonState(nil)
end

function menu:OnShowMenu(frame)
  frame.dataTable:RefreshData()
  frame.dataTable:EnableUpdates(true)
  setButtonState(frame.dataTable:GetSelectedRow())
end

function menu:OnLeaveMenu(frame)
  frame.dataTable:EnableUpdates(false)
end