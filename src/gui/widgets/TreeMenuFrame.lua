local _, addon = ...
local CreateFrame, strsplit = addon.G.CreateFrame, addon.G.strsplit
local AceGUI = addon.AceGUI

local widget = addon.CustomWidgets:NewWidget("TreeMenuFrame")

local function getOrCreateScreen(frame, menuId)
  -- If the screen has already been built, return it
  local existing = frame._screens[menuId]
  if existing then return existing end

  -- Otherwise, Create it for the first time
  local menu = frame._menus[menuId]
  if not menu then
    return -- No screen registered for this ID
  end
  if type(menu.Create) ~= "function" then
    error("Failed to load menu screen: screen "..menuId.." does not have a Create function")
  end

  local container = CreateFrame("Frame", nil, frame._contentFrame)
  container:SetAllPoints(true)
  container:Show()
  menu:Create(container)

  -- Hook up the OnShowMenu and OnLeaveMenu functions from the template
  container.OnShowMenu = function(self, ...)
    if menu.OnShowMenu then
      menu:OnShowMenu(self, ...)
    end
  end
  container.OnLeaveMenu = function(self, ...)
    if menu.OnLeaveMenu then
      menu:OnLeaveMenu(self, ...)
    end
  end
  frame._screens[menuId] = container
  return container
end

-- Expand this menu tree
local function setTreeDepth(tree, layerDepth, targetDepth, groups)
  for _, menu in ipairs(tree) do
    if menu.children then
      groups[menu.value] = layerDepth < targetDepth
      setTreeDepth(menu.children, layerDepth + 1, targetDepth, groups)
    end
  end
end

local function findMenuItemByValue(tree, value, groups)
  for _, menu in ipairs(tree) do
    if menu.value == value then
      return menu
    elseif menu.children then
      local found = findMenuItemByValue(menu.children, value, groups)
      if found then
        groups[menu.value] = true -- The parent was on the path - expand it!
        return found
      end
    end
  end
end

-- This seems to be the only reliable way to highlight the menu item programatically
-- I don't entirely understand why it works
local function simulateMenuItemClick(tmf, menuItem)
  local button
  for _, b in ipairs(tmf._aceTreeGroup.buttons) do
    if b.value == menuItem.value then
      button = b
      break
    end
  end
  if button then
    button.selected = true
    -- The button must be "clicked" on the frame after button.selected is set to true
    addon.Ace:ScheduleTimer(function()
      button:GetScript("OnClick")(button)
    end, 0.033)
  end
end

local methods = {
  ["NewMenuScreen"] = function(self, menuId, headingText)
    local st = { headingText = headingText }
    if self._menus[menuId] then
      addon.UILogger:Error("Failed to register NewMenuScreen: screen already exists with id %s", menuId)
      return st
    end
    self._menus[menuId] = st
    return st
  end,
  ["NavToMenuScreen"] = function(self, menuId, ...)
    addon.MainMenu:Show()
    local statusTable = self._aceTreeGroup.status
    local menuItem = findMenuItemByValue(self._aceMenuTree, menuId, statusTable.groups)
    if menuItem then
      -- Expand the menu tree to show the path to this item
      self._aceTreeGroup:SetStatusTable(statusTable)
      -- "Click" on the item so that it's highlighted
      simulateMenuItemClick(self, menuItem)
      -- Even still, you have to navigate to the item by value to ensure OnGroupSelected fires
      -- This will likely result in it firing twice, but oh well
      self._aceTreeGroup:SelectByValue(menuItem.value)
    end
  end,
  ["ShowMenuScreen"] = function(self, menuId, ...)
    self:Show()

    if menuId then
      local ok, screen = pcall(getOrCreateScreen, self, menuId)
      if not ok then
        addon.UILogger:Error("Failed to create menu screen %s: %s", menuId, screen)
        return
      elseif not screen then
        -- addon.UILogger:Warn("No screen registered with id: %s", menuId)
        return
      end

      if self._selectedScreen then
        self._selectedScreen:OnLeaveMenu()
        self._selectedScreen:Hide()
      end
      self._selectedScreen = screen

      addon.UILogger:Trace("Showing menu with id: %s", menuId)
      screen:OnShowMenu(...)
      screen:Show()
    end
  end,
  ["SetTitle"] = function(self, text)
    self._aceFrame:SetTitle(text)
  end,
  ["SetStatusText"] = function(self, text)
    self._aceFrame:SetStatusText(text)
  end,
  ["SetMenuTree"] = function(self, menuTree)
    self._aceMenuTree = menuTree
    self._aceTreeGroup:SetTree(menuTree)
  end,
  ["SetVisibleTreeDepth"] = function(self, depth)
    local statusTable, groups = self._aceTreeGroup.status, {}
    statusTable.groups = groups
    setTreeDepth(self._aceMenuTree, 1, depth, groups)
    self._aceTreeGroup:SetStatusTable(statusTable)
  end
}

-- This is the entry point for accessing a primary menu screen
local function OnGroupSelected(container, event, group)
  local frame = container._treeMenuFrame
  local parts = { strsplit("\001", group) } -- Ace uses this character as a path delimiter
  local id = parts[#parts]
  frame:ShowMenuScreen(id)
end

function widget:Create()
  local aceFrame = AceGUI:Create("Frame")
  aceFrame:SetLayout("Fill") -- Fill the entire frame with the TreeGroup widget

  local aceTreeGroup = AceGUI:Create("TreeGroup")
  aceTreeGroup:EnableButtonTooltips(false)
  aceTreeGroup:SetCallback("OnGroupSelected", function(...)
    addon:catch(OnGroupSelected, ...)
  end)
  aceTreeGroup:SetStatusTable({}) -- For some reason, this is not set by default
  aceFrame:AddChild(aceTreeGroup)

  -- This container is the first parameter passed to OnGroupSelect
  local contentContainer = aceTreeGroup.content.obj

  -- local heading = AceGUI:Create("Heading")
  -- heading:SetFullWidth(true)
  -- contentContainer:AddChild(heading)

  local contentGroup = AceGUI:Create("SimpleGroup")
  contentGroup:SetFullWidth(true)
  contentGroup:SetFullHeight(true)
  contentContainer:AddChild(contentGroup)

  -- CustomWidgets are expected to be Blizzard frames rather than Ace frames
  -- so that's what we'll return from Create
  local frame = aceFrame.frame
  frame:SetFrameStrata("HIGH") -- default Ace frame strata is too high

  frame._aceFrame = aceFrame
  frame._aceMenuTree = {}
  frame._aceTreeGroup = aceTreeGroup
  -- frame._aceHeading = heading
  frame._contentFrame = contentGroup.frame -- Menu contents will be drawn here
  frame._screens = {}
  frame._menus = {}

  -- Give OnGroupSelect a quick way to access the top-level frame
  contentContainer._treeMenuFrame = frame

  for name, method in pairs(methods) do
    frame[name] = method
  end

  frame:Hide()
  return frame
end
