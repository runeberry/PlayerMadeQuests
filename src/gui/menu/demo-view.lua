local _, addon = ...
local CreateFrame = addon.G.CreateFrame
local QuestDemos, QuestLog = addon.QuestDemos, addon.QuestLog

local menu = addon.MainMenu:NewMenuScreen([[demo-view]], "Demo Quest View")

-- Temporarily store an id here to use it with the onclick functions
local currentDemoId = nil

local function button_Back()
  addon.MainMenu:Show("demo")
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

function menu:Create(parent)
  local frame = CreateFrame("Frame", nil, parent)
  frame:SetAllPoints(true)
  frame:Hide()

  local nameField = addon.CustomWidgets:CreateWidget("TextInput", frame, "Quest Name")
  nameField:SetEnabled(false)
  nameField:SetPoint("TOPLEFT", frame, "TOPLEFT")
  nameField:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
  nameField:OnEnterPressed(function(text) addon.Logger:Info(text) end)

  local descField = addon.CustomWidgets:CreateWidget("TextInputScrolling", frame, "Quest Description")
  descField:SetEnabled(false)
  descField:SetPoint("TOPLEFT", nameField, "BOTTOMLEFT")
  descField:SetPoint("TOPRIGHT", nameField, "BOTTOMRIGHT")
  descField:SetHeight(100)

  local buttonPane = addon.CustomWidgets:CreateWidget("ButtonPane", frame, "BOTTOM")
  -- bug: This should default to LEFT anchor, but it's defaulting to TOP for some reason? Investigate...
  buttonPane:AddButton("Back", button_Back, { anchor = "LEFT" })
  buttonPane:AddButton("Accept", button_Accept, { anchor = "RIGHT" })
  buttonPane:AddButton("Copy to Drafts", button_CopyToDrafts, { anchor = "RIGHT" })

  local scriptEditor = addon.CustomWidgets:CreateWidget("TextInputScrolling", frame, "QuestScript")
  scriptEditor:SetEnabled(false)
  scriptEditor:SetPoint("TOPLEFT", descField, "BOTTOMLEFT")
  scriptEditor:SetPoint("BOTTOMRIGHT", buttonPane, "TOPRIGHT")

  frame.nameField = nameField
  frame.descField = descField
  frame.scriptEditor = scriptEditor

  return frame
end

function menu:OnShow(frame, demoId)
  currentDemoId = demoId
  local demo = QuestDemos:FindByID(demoId)
  if not demo then
    addon.Logger:Error("No demo available with id:", demoId)
  end
  frame.nameField:SetText(demo.parameters.name)
  frame.descField:SetText(demo.parameters.description)
  frame.scriptEditor:SetText(demo.script)
end

function menu:OnHide(frame)
  currentDemoId = nil
  frame.nameField:SetText()
  frame.descField:SetText()
  frame.scriptEditor:SetText()
end
