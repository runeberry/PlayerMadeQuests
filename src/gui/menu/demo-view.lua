local _, addon = ...
local QuestDemos = addon.QuestDemos

local menu = addon.MainMenu:NewMenuScreen("demo-view")

-- Temporarily store an id here to use it with the onclick functions
local currentDemoId = nil

local function button_Back()
  addon.MainMenu:NavToMenuScreen("demo")
end

local function button_Accept()
  if not currentDemoId then return end
  local ok, quest = addon.QuestDemos:CompileDemo(currentDemoId)
  if not ok then
    addon.Logger:Error("Failed to accept demo quest:", quest)
    return
  end
  addon.AppEvents:Publish("QuestInvite", quest)
end

local function button_CopyToDrafts()
  if not currentDemoId then return end
  addon.QuestDemos:CopyToDrafts(currentDemoId)
  addon.Logger:Info("Demo quest copied to drafts.")
end

function menu:Create(frame)
  local nameField = addon.CustomWidgets:CreateWidget("TextInput", frame, "Quest Name")
  nameField:SetEnabled(false)
  nameField:SetPoint("TOPLEFT", frame, "TOPLEFT")
  nameField:SetPoint("TOPRIGHT", frame, "TOPRIGHT")

  local descField = addon.CustomWidgets:CreateWidget("TextInputScrolling", frame, "Description")
  descField:SetEnabled(false)
  descField:SetPoint("TOPLEFT", nameField, "BOTTOMLEFT")
  descField:SetPoint("TOPRIGHT", nameField, "BOTTOMRIGHT")
  descField:SetHeight(100)

  local buttonPane = addon.CustomWidgets:CreateWidget("ButtonPane", frame, "BOTTOM")
  -- bug: This should default to LEFT anchor, but it's defaulting to TOP for some reason? Investigate...
  buttonPane:AddButton("Back", button_Back, { anchor = "LEFT" })
  buttonPane:AddButton("Accept", button_Accept, { anchor = "RIGHT" })
  buttonPane:AddButton("Copy to Drafts", button_CopyToDrafts, { anchor = "RIGHT" })

  local scriptEditor = addon.CustomWidgets:CreateWidget("ScriptEditor", frame, "Script")
  scriptEditor:SetEnabled(false)
  scriptEditor:SetPoint("TOPLEFT", descField, "BOTTOMLEFT")
  scriptEditor:SetPoint("BOTTOMRIGHT", buttonPane, "TOPRIGHT")

  frame.nameField = nameField
  frame.descField = descField
  frame.scriptEditor = scriptEditor

  return frame
end

function menu:OnShowMenu(frame, demoId)
  currentDemoId = demoId
  local demo = QuestDemos:FindByID(demoId)
  if not demo then
    addon.Logger:Error("No demo available with id:", demoId)
    error("No demo available with id:", demoId)
    return
  end
  frame.nameField:SetText(demo.parameters.name)
  frame.descField:SetText(demo.parameters.description)
  frame.scriptEditor:SetText(demo.script)

  frame.scriptEditor:RefreshStyle()
end

function menu:OnLeaveMenu(frame)
  currentDemoId = nil
  frame.nameField:SetText()
  frame.descField:SetText()
  frame.scriptEditor:SetText()
end
