local _, addon = ...
local AceGUI, strsplit, UISpecialFrames = addon.AceGUI, addon.G.strsplit, addon.G.UISpecialFrames
local addonVersion = addon:GetVersion()

addon.MainMenu = {}
local mmfGlobalName = "PMQ_MainMenuFrame"
local menuTree = {}
local menuScreensById = {}
local menuPathsById = {}
local menuScreensByPath = {}
local mainMenuWidget, treeGroupWidget, selectedScreen, groupSelectContainer

local function getOrCreateMenuTreeItem(menu, value)
  for _, m in pairs(menu) do
    if m.value == value then
      return m
    end
  end

  local newItem = { value = value, name = value }
  table.insert(menu, newItem)
  return newItem
end

local function openMenuScreen(container, screen, ...)
  local prevScreen = selectedScreen
  selectedScreen = screen
  if type(screen.Create) ~= "function" then
    -- No screen for this menu item
    return
  end

  container:ReleaseChildren()

  local heading = AceGUI:Create("Heading")
  heading:SetFullWidth(true)
  heading:SetText(screen.heading)
  container:AddChild(heading)

  local contentGroup = AceGUI:Create("SimpleGroup")
  contentGroup:SetFullWidth(true)
  contentGroup:SetFullHeight(true)
  container:AddChild(contentGroup)

  if not screen.frame then
    screen.frame = screen:Create(contentGroup.frame)
  end

  if prevScreen then
    if prevScreen.frame then
      prevScreen.frame:Hide()
    end
    if prevScreen.OnHide then
      prevScreen:OnHide(prevScreen.frame)
    end
  end

  if screen.frame then
    screen.frame:Show()
  end
  if screen.OnShow then
    -- Varargs can be handled on the screen's OnShow function
    screen:OnShow(screen.frame, ...)
  end

  contentGroup.frame:Show()
end

-- This is the entry point for accessing a primary menu screen
local function OnGroupSelected(container, event, group)
  local path = group:gsub("\001", [[\]])
  local screen = menuScreensByPath[path]
  if not screen then
    -- addon.Logger:Table(menuScreensByPath)
    -- addon.Logger:Error("No menu screen registered at path:", path)
    return
  end
  openMenuScreen(container, screen)
end

local function OnClose(widget)
  mainMenuWidget = nil
  treeGroupWidget = nil
  if selectedScreen and selectedScreen.frame then
    selectedScreen.frame:Hide()
  end
  selectedScreen = nil
  AceGUI:Release(widget)
end

local function OnShow()
  mainMenuWidget = AceGUI:Create("Frame")
  mainMenuWidget.frame:SetFrameStrata("HIGH")
  mainMenuWidget:SetTitle("PlayerMadeQuests")
  mainMenuWidget:SetStatusText("PMQ v"..addonVersion.." (thank you for testing! <3)")
  mainMenuWidget:SetCallback("OnClose", OnClose)
  mainMenuWidget:SetLayout("Fill") -- Fill the entire frame with the TabGroup widget

  treeGroupWidget = AceGUI:Create("TreeGroup")
  treeGroupWidget:EnableButtonTooltips(false)
  treeGroupWidget:SetTree(menuTree)
  treeGroupWidget:SetCallback("OnGroupSelected", function(...)
    addon:catch(OnGroupSelected, ...)
  end)
  mainMenuWidget:AddChild(treeGroupWidget)

  -- Make closable with ESC
  _G[mmfGlobalName] = mainMenuWidget.frame
  table.insert(UISpecialFrames, mmfGlobalName)

  -- This is the first parameter passed to OnGroupSelect
  groupSelectContainer = treeGroupWidget.content.obj
end

function addon.MainMenu:Show(menuId, ...)
  if not mainMenuWidget then
    OnShow()
  end
  if menuId then
    if menuPathsById[menuId] then
      -- There's a path from the top level, so perform a full navigation to this menu
      addon.Logger:Trace("Navigating to menu at id/path:", menuId, menuPathsById[menuId])
      treeGroupWidget:SelectByValue(menuId)
    elseif menuScreensById[menuId] then
      -- It's an ID, just load the menu into frame
      local screen = menuScreensById[menuId]
      if screen then
        addon.Logger:Trace("Showing menu with id:", menuId)
        openMenuScreen(groupSelectContainer, screen, ...)
      else
        addon.Logger:Warn("No menu screen registered with id:", menuId)
      end
    end
  end
end

function addon.MainMenu:Hide()
  if not mainMenuWidget then return end
  OnClose(mainMenuWidget)
end

function addon.MainMenu:NewMenuScreen(path, text, addToTree)
  if not path or not text then
    addon.Logger:Warn("Failed to build menu: path and text are required")
    return {}
  end

  local obj = {
    heading = text
  }

  local menuId
  if addToTree then
    -- If a path is specified, insert it into the top-level menu
    -- Only going 3 levels deep for menu
    local t1, t2, t3 = strsplit([[\]], path)
    local t1m, t2m, menu
    if t3 then
      t1m = getOrCreateMenuTreeItem(menuTree, t1)
      t1m.children = t1m.children or {}
      t2m = getOrCreateMenuTreeItem(t1m.children, t2)
      t2m.children = t2m.children or {}
      menu = getOrCreateMenuTreeItem(t2m.children, t3)
    elseif t2 then
      t1m = getOrCreateMenuTreeItem(menuTree, t1)
      t1m.children = t1m.children or {}
      menu = getOrCreateMenuTreeItem(t1m.children, t2)
    elseif t1 then
      menu = getOrCreateMenuTreeItem(menuTree, t1)
    else
      addon.Logger:Warn("Failed to build menu at path:", path)
      return {}
    end
    menu.text = text
    menuId = menu.value
    menuScreensByPath[path] = obj
    menuPathsById[menuId] = path
  else
    menuId = path
  end

  menuScreensById[menuId] = obj
  addon.Logger:Trace("Registered menu at path:", path)
  return obj
end

addon:OnSaveDataLoaded(function()
  addon.MainMenu:NewMenuScreen([[help]], "Help", true)
  if addon.SHOW_MENU_ON_START then
    addon.MainMenu:Show(addon.SHOW_MENU_ON_START)
  end
end)