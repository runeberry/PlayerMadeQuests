local _, addon = ...
local CreateFrame, strsplit = addon.G.CreateFrame, addon.G.strsplit
local AceGUI = addon.AceGUI

local widget = addon.CustomWidgets:NewWidget("TreeMenuFrame")

local function getOrCreateScreen(frame, menuId)
  local screen = frame._screens[menuId]
  if not screen then
    local parentFrame = CreateFrame("Frame", nil, frame._contentFrame)
    parentFrame:SetAllPoints(true)
    parentFrame:Show()

    local menu = frame._menus[menuId]
    if not menu then
      return -- No screen registered for this ID
    end
    if type(menu.Create) ~= "function" then
      error("Failed to load menu screen: screen "..menuId.." does not have a Create function")
    end

    screen = menu:Create(parentFrame)
    if not screen then
      error("Failed to load menu screen: Create did not return a screen for menu "..menuId)
    end
    -- Hook up the OnShowMenu and OnLeaveMenu functions from the template
    screen.OnShowMenu = function(self, ...)
      if menu.OnShowMenu then
        menu:OnShowMenu(self, ...)
      end
    end
    screen.OnLeaveMenu = function(self, ...)
      if menu.OnLeaveMenu then
        menu:OnLeaveMenu(self, ...)
      end
    end
    frame._screens[menuId] = screen
  end
  return screen
end

local methods = {
  ["NewMenuScreen"] = function(self, menuId)
    local st = {}
    if self._menus[menuId] then
      addon.Logger:Error("Failed to register NewMenuScreen: screen already exists with id", menuId)
      return st
    end
    self._menus[menuId] = st
    return st
  end,
  ["NavToMenuScreen"] = function(self, menuId, ...)
    -- bug: This doesn't properly expand the menu when the menu at this id is nested
    self._aceTreeGroup:SelectByValue(menuId)
  end,
  ["ShowMenuScreen"] = function(self, menuId, ...)
    self:Show()

    if menuId then
      local screen = getOrCreateScreen(self, menuId)
      if not screen then return end -- No screen registered for this ID

      if self._selectedScreen then
        self._selectedScreen:OnLeaveMenu()
        self._selectedScreen:Hide()
      end
      self._selectedScreen = screen

      addon.Logger:Trace("Showing menu with id:", menuId)
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

function widget:OnShow(frame, id, ...)

end
