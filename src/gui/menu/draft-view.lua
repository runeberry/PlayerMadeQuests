local _, addon = ...
local CreateFrame = addon.G.CreateFrame
local QuestDrafts, QuestEngine = addon.QuestDrafts, addon.QuestEngine

local menu = addon.MainMenu:NewMenuScreen([[draft-view]], "Edit Quest Draft")

local frame
local currentDraft = nil

local function button_Back()
  addon.MainMenu:Show("drafts")
end

local function button_Validate()
  local parameters = QuestEngine:Compile(currentDraft.script, currentDraft.parameters)
  QuestEngine:Build(parameters)
  addon.Logger:Info("Your quest looks good! No errors detected.")
end

local function button_Save()
  currentDraft.parameters.name = frame.nameField:GetText()
  currentDraft.script = frame.scriptEditor:GetText()

  currentDraft = addon:CopyTable(QuestDrafts:SaveDraft(currentDraft))
  addon.Logger:Info("Draft Saved -", currentDraft.parameters.name)
end

function menu:Create(parent)
  frame = CreateFrame("Frame", nil, parent)
  frame:SetAllPoints(true)
  frame:Hide()

  local nameField = addon.CustomWidgets:CreateWidget("TextInput", frame, "Quest Name")
  nameField:SetPoint("TOPLEFT", frame, "TOPLEFT")
  nameField:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
  nameField:OnEnterPressed(function(text) addon.Logger:Info(text) end)

  local buttonPane = addon.CustomWidgets:CreateWidget("ButtonPane", frame, "BOTTOM")
  -- bug: This should default to LEFT anchor, but it's defaulting to TOP for some reason? Investigate...
  buttonPane:AddButton("Back", button_Back, { anchor = "LEFT" })
  buttonPane:AddButton("Save", button_Save, { anchor = "RIGHT" })
  buttonPane:AddButton("Validate", button_Validate, { anchor = "RIGHT" })

  local scriptEditor = addon.CustomWidgets:CreateWidget("TextInputScrolling", frame, "QuestScript")
  scriptEditor:SetPoint("TOPLEFT", nameField, "BOTTOMLEFT")
  scriptEditor:SetPoint("BOTTOMRIGHT", buttonPane, "TOPRIGHT")

  frame.nameField = nameField
  frame.scriptEditor = scriptEditor

  return frame
end

function menu:OnShow(frame, draftId)
  local draft
  if draftId then
    draft = QuestDrafts:GetDraftByID(draftId)
    if not draft then
      addon.Logger:Error("No draft available with id:", draftId)
      return
    end
  else
    draft = QuestDrafts:NewDraft("New Quest")
  end

  currentDraft = addon:CopyTable(draft)
  frame.nameField:SetText(currentDraft.parameters.name)
  frame.scriptEditor:SetText(currentDraft.script)
end

function menu:OnHide(frame)
  currentDraft = nil
  frame.nameField:SetText()
  frame.scriptEditor:SetText()
end