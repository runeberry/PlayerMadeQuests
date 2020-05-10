local _, addon = ...
local AceGUI, strsplit = addon.AceGUI, addon.G.strsplit
local addonVersion = addon:GetVersion()

addon.MainMenu = {}
local menuTree = {}
local menuScreens = {}
local savedSettings, mainMenuWidget, treeGroupWidget

local function getOrCreateMenu(menu, value)
  for _, m in pairs(menu) do
    if m.value == value then
      return m
    end
  end

  local newItem = { value = value, text = value }
  table.insert(menu, newItem)
  return newItem
end

local function OnGroupSelected(container, event, group)
  local errPrefix = "Failed to build MainMenu screen:"

  local selectedScreen = menuScreens[group]
  if selectedScreen == nil then
    addon:error(errPrefix, "no screen registered for group", group)
    return
  end
  if type(selectedScreen.Create) ~= "function" then
    -- No screen for this menu item
    return
  end

  container:ReleaseChildren()

  local currentScreen = container:GetUserData("CurrentMenuScreen")
  if currentScreen then
    container:SetUserData("CurrentMenuScreen", nil)
    if currentScreen.frame then
      currentScreen.frame:Hide()
    end
    if currentScreen.OnHide then
      currentScreen:OnHide(currentScreen.frame)
    end
  end

  local heading = AceGUI:Create("Heading")
  heading:SetFullWidth(true)
  heading:SetText(selectedScreen.heading)
  container:AddChild(heading)

  local contentGroup = AceGUI:Create("SimpleGroup")
  contentGroup:SetFullWidth(true)
  contentGroup:SetFullHeight(true)
  container:AddChild(contentGroup)

  if not selectedScreen.frame then
    local ok, frame = addon:catch(selectedScreen.Create, selectedScreen, contentGroup.frame)
    if not ok then
      addon:error(errPrefix, frame)
      return
    end
    selectedScreen.frame = frame
  end

  if selectedScreen.frame then
    selectedScreen.frame:Show()
  end
  if selectedScreen.OnShow then
    selectedScreen:OnShow(selectedScreen.frame)
  end

  -- Show the selected screen
  contentGroup.frame:Show()
  container:SetUserData("CurrentMenuScreen", selectedScreen)
end

local function OnClose(widget)
  mainMenuWidget = nil
  treeGroupWidget = nil
  AceGUI:Release(widget)
end

local function OnShow()
  mainMenuWidget = AceGUI:Create("Frame")
  mainMenuWidget:SetTitle("PlayerMadeQuests")
  mainMenuWidget:SetStatusText("PMQ v"..addonVersion.." (thank you for testing! <3)")
  mainMenuWidget:SetCallback("OnClose", OnClose)
  mainMenuWidget:SetLayout("Fill") -- Fill the entire frame with the TabGroup widget

  treeGroupWidget = AceGUI:Create("TreeGroup")
  treeGroupWidget:EnableButtonTooltips(false)
  treeGroupWidget:SetTree(menuTree)
  treeGroupWidget:SetCallback("OnGroupSelected", OnGroupSelected)
  mainMenuWidget:AddChild(treeGroupWidget)
end

function addon.MainMenu:Show()
  if mainMenuWidget then return end
  OnShow()
end

function addon.MainMenu:Hide()
  if not mainMenuWidget then return end
  OnClose(mainMenuWidget)
end

function addon.MainMenu:NewMenuScreen(path, text)
  -- Only going 3 levels deep for menu
  local t1, t2, t3 = strsplit([[\]], path)
  local t1m, t2m, menu
  if t3 then
    t1m = getOrCreateMenu(menuTree, t1)
    if not t1m.children then t1m.children = {} end
    t2m = getOrCreateMenu(t1m.children, t2)
    if not t2m.children then t2m.children = {} end
    menu = getOrCreateMenu(t2m.children, t3)
  elseif t2 then
    t1m = getOrCreateMenu(menuTree, t1)
    if not t1m.children then t1m.children = {} end
    menu = getOrCreateMenu(t1m.children, t2)
  elseif t1 then
    menu = getOrCreateMenu(menuTree, t1)
  else
    addon:warn("Unable to build menu at path:", path)
    return {}
  end

  menu.text = text or menu.value

  local obj = {
    heading = menu.text
  }
  path = path:gsub([[\]], "\001") -- to match Ace's crazy format
  menuScreens[path] = obj
  return obj
end

addon:OnSaveDataLoaded(function()
  savedSettings = addon.SaveData:LoadTable("Settings")
  addon.MainMenu:NewMenuScreen([[help]], "Help")
  -- addon.MainMenu:Show()
end)