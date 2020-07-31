local _, addon = ...
local QuestDemos = addon.QuestDemos

local menu = addon.MainMenu:NewMenuScreen("demo-view")

-- Temporarily store an id here to use it with the onclick functions
local currentDemoId = nil

local textinfo = {
  static = true,
  styles = addon.DefaultArticleTextStyle,
  text = {
    { style = "page-header", text = "DEMO_NAME" },
    { style = "default", text = "DEMO_INFO" },
  }
}

local function button_Back()
  addon.MainMenu:NavToMenuScreen("demo")
end

local function button_Start()
  if not currentDemoId then return end
  local ok, quest = addon.QuestDemos:CompileDemo(currentDemoId)
  if not ok then
    addon.Logger:Error("Failed to accept demo quest: %s", quest)
    return
  end
  addon.QuestDemos:StartDemo(currentDemoId)
end

local function button_CopyToDrafts()
  if not currentDemoId then return end
  local demo = addon.QuestDemos:FindByID(currentDemoId)
  addon.StaticPopups:Show("RenameDemoCopy", demo)
end

function menu:Create(frame)
  local articleText = addon.CustomWidgets:CreateWidget("ArticleText", frame, textinfo)
  articleText:ClearAllPoints()
  articleText:SetPoint("TOPLEFT", frame, "TOPLEFT")
  articleText:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
  articleText:SetHeight(120)

  local buttonPane = addon.CustomWidgets:CreateWidget("ButtonPane", frame, "BOTTOM")
  -- bug: This should default to LEFT anchor, but it's defaulting to TOP for some reason? Investigate...
  buttonPane:AddButton("Back", button_Back, { anchor = "LEFT" })
  buttonPane:AddButton("Start Quest", button_Start, { anchor = "RIGHT" })
  buttonPane:AddButton("Copy to Drafts", button_CopyToDrafts, { anchor = "RIGHT" })

  local scriptEditor = addon.CustomWidgets:CreateWidget("ScriptEditor", frame, "Quest Script")
  scriptEditor:SetEnabled(false)
  scriptEditor:SetPoint("TOPLEFT", articleText, "BOTTOMLEFT")
  scriptEditor:SetPoint("BOTTOMRIGHT", buttonPane, "TOPRIGHT")

  frame.nameField = articleText:GetFontString(1)
  frame.descField = articleText:GetFontString(2)
  frame.scriptEditor = scriptEditor

  return frame
end

function menu:OnShowMenu(frame, demoId)
  currentDemoId = demoId
  local demo = QuestDemos:FindByID(demoId)
  if not demo then
    error("No demo available with id: "..demoId)
    return
  end
  frame.nameField:SetText(demo.demoName)
  frame.descField:SetText(demo.helpText)
  frame.scriptEditor:SetText(demo.script)

  frame.scriptEditor:RefreshStyle()
end

function menu:OnLeaveMenu(frame)
  currentDemoId = nil
  frame.nameField:SetText("DEMO_NAME")
  frame.descField:SetText("DEMO_INFO")
  frame.scriptEditor:SetText()
end
