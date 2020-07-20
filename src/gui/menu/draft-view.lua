local _, addon = ...
local QuestDrafts = addon.QuestDrafts

local menu = addon.MainMenu:NewMenuScreen("draft-view")

local currentFrame
local currentDraft

local function checkDirty()
  return currentFrame.nameField:IsDirty() or
    currentFrame.descField:IsDirty() or
    currentFrame.scriptEditor:IsDirty()
end

local function cleanForm()
  currentFrame.nameField:SetDirty(false)
  currentFrame.descField:SetDirty(false)
  currentFrame.scriptEditor:SetDirty(false)
end

local function navBack()
  addon.MainMenu:NavToMenuScreen("drafts")
end

local function writeFields(draft)
  draft.parameters.name = currentFrame.nameField:GetText()
  draft.parameters.description = currentFrame.descField:GetText()
  draft.script = currentFrame.scriptEditor:GetText()
end

local function button_Save()
  if not currentDraft then return end
  writeFields(currentDraft)
  QuestDrafts:Save(currentDraft)
  cleanForm()
  addon.Logger:Info("Draft Saved -", currentDraft.parameters.name)
end

local function button_Back()
  if checkDirty() then
    addon.StaticPopups:Show("ExitDraft", button_Save)
  else
    navBack()
  end
end

local function compile()
  local draftCopy = addon:CopyTable(currentDraft)
  writeFields(draftCopy)
  return addon.QuestScriptCompiler:TryCompile(currentDraft.script, currentDraft.parameters)
end

local function button_Validate()
  if not currentDraft then return end
  local ok, quest = compile()
  if not ok then
    addon.Logger:Warn("Your quest contains an error:")
    addon.Logger:Warn(quest)
    return
  end
  addon.Logger:Info("Your quest looks good! No errors detected.")
end

function menu:Create(frame)
  local nameField = addon.CustomWidgets:CreateWidget("TextInput", frame, "Quest Name")
  nameField:SetPoint("TOPLEFT", frame, "TOPLEFT")
  nameField:SetPoint("TOPRIGHT", frame, "TOPRIGHT")

  local descField = addon.CustomWidgets:CreateWidget("TextInputScrolling", frame, "Description")
  descField:SetPoint("TOPLEFT", nameField, "BOTTOMLEFT")
  descField:SetPoint("TOPRIGHT", nameField, "BOTTOMRIGHT")
  descField:SetHeight(100)

  local buttonPane = addon.CustomWidgets:CreateWidget("ButtonPane", frame, "BOTTOM")
  -- bug: This should default to LEFT anchor, but it's defaulting to TOP for some reason? Investigate...
  buttonPane:AddButton("Back", button_Back, { anchor = "LEFT" })
  buttonPane:AddButton("Save", button_Save, { anchor = "RIGHT" })
  buttonPane:AddButton("Validate", button_Validate, { anchor = "RIGHT" })

  local scriptEditor = addon.CustomWidgets:CreateWidget("ScriptEditor", frame, "Script")
  scriptEditor:SetPoint("TOPLEFT", descField, "BOTTOMLEFT")
  scriptEditor:SetPoint("BOTTOMRIGHT", buttonPane, "TOPRIGHT")

  frame.nameField = nameField
  frame.descField = descField
  frame.scriptEditor = scriptEditor
end

function menu:OnShowMenu(frame, draftId)
  currentFrame = frame
  if draftId then
    currentDraft = QuestDrafts:FindByID(draftId)
    if not currentDraft then
      addon.Logger:Error("No draft available with id:", draftId)
      return
    end
  else
    currentDraft = QuestDrafts:NewDraft()
    currentDraft.parameters.name = "New Quest"
    currentDraft.script = "objectives:\n  - "
  end

  frame.nameField:SetText(currentDraft.parameters.name)
  frame.descField:SetText(currentDraft.parameters.description)
  frame.scriptEditor:SetText(currentDraft.script)
  addon.Ace:ScheduleTimer(function()
    -- Force the scrollFrame to start at the top whenever the text is changed
    -- Seems the WoW client can't correctly set scroll until the next frame
    frame.descField.scrollFrame:SetVerticalScroll(0)
    frame.scriptEditor.scrollFrame:SetVerticalScroll(0)
  end, 0.033)
  cleanForm()

  frame.scriptEditor:RefreshStyle()
end

function menu:OnLeaveMenu(frame)
  currentFrame = nil
  currentDraft = nil
  frame.nameField:SetText()
  frame.descField:SetText()
  frame.scriptEditor:SetText()
end