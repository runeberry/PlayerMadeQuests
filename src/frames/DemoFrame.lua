local _, addon = ...
local AceGUI = addon.AceGUI

local textStore

local function DrawGroup1(container)
  local editbox = AceGUI:Create("EditBox")
  editbox:SetLabel("Insert text:")
  editbox:SetWidth(200)
  editbox:SetCallback("OnEnterPressed", function(widget, event, text) textStore = text end)
  container:AddChild(editbox)

  local button = AceGUI:Create("Button")
  button:SetText("Click Me!")
  button:SetWidth(200)
  button:SetCallback("OnClick", function() print(textStore) end)
  container:AddChild(button)
end

local function DrawGroup2(container)
  local desc = AceGUI:Create("Label")
  desc:SetText("This is Tab 2")
  desc:SetFullWidth(true)
  container:AddChild(desc)

  local button = AceGUI:Create("Button")
  button:SetText("Tab 2 Button")
  button:SetWidth(200)
  container:AddChild(button)
end

local function DrawGroup3(container)
  local desc = AceGUI:Create("Label")
  desc:SetText("This is Tab 3")
  desc:SetFullWidth(true)
  container:AddChild(desc)

  local button = AceGUI:Create("Button")
  button:SetText("Tab 3 Button")
  button:SetWidth(200)
  container:AddChild(button)
end

local function SelectGroup(container, event, group)
  container:ReleaseChildren()
  if group == "tab1" then
    DrawGroup1(container)
  elseif group == "tab2" then
    DrawGroup2(container)
  elseif group == "tab3" then
    DrawGroup3(container)
  end
end

local function OnClose(widget)
  PlayerMadeQuestsCache.IsDemoFrameShown = nil
  AceGUI:Release(widget)
end

function addon:ShowDemoFrame()
  if PlayerMadeQuestsCache.IsDemoFrameShown == true then
    return
  end

  local frame = AceGUI:Create("Frame")
  frame:SetTitle("AceGUI Demo Frame")
  frame:SetStatusText("AceGUI Example Container Frame")
  frame:SetCallback("OnClose", OnClose)
  frame:SetLayout("Fill") -- Fill the entire frame with the TabGroup widget

  local tabGroup = AceGUI:Create("TabGroup")
  tabGroup:SetLayout("Flow")
  tabGroup:SetTabs({
    { text = "Tab 1", value = "tab1" },
    { text = "Tab 2", value = "tab2" },
    { text = "Tab 2", value = "tab3" },
  })
  tabGroup:SetCallback("OnGroupSelected", SelectGroup)
  tabGroup:SelectTab("tab1")
  frame:AddChild(tabGroup)

  -- Make window close when ESC is pressed
  -- Adapted from: https://stackoverflow.com/a/61215014
  _G["PMQ_DemoFrame"] = frame.frame
  table.insert(UISpecialFrames, "PMQ_DemoFrame")

  PlayerMadeQuestsCache.IsDemoFrameShown = true
end