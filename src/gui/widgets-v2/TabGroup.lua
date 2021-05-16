local _, addon = ...
local asserttype, assertf, assertframe = addon.asserttype, addon.assertf, addon.assertframe
local unpack = addon.G.unpack

local template = addon:NewFrame("TabGroup")

template:RegisterCustomScriptEvent("OnTabSelect")

local defaultOptions = {
  tabHeight = 24,               -- [number] Override height of the tab bar, in px
  tabs = {},
  autoCreateTabContent = true   -- [bool] Should empty content frames be created automatically?
}

-- See ButtonGroup for info
local defaultButtonGroupOptions = {
  template = "TabButtonTemplate", -- "OptionsFrameTabButtonTemplate"
  sizeMode = "tab",
  margin = 0,
  padding = { 8, 8, 0, 0 }, -- bug: this won't merge properly with base, it concats instead
  spacing = 0,

  anchor = "LEFT",

  buttons = {},
}

local function buildButtonGroupOptions(tabGroup, tabs)
  asserttype(tabs, "table", "tabs")

  -- Translate the "tabs" options into options for the underlying ButtonGroup
  local buttonGroupOptions = addon:CopyTable(defaultButtonGroupOptions)
  for i, tab in ipairs(tabs) do
    local buttonHandler = function()
      tabGroup:SelectTab(i)
    end
    local buttonOption

    if type(tab) == "table" then
      buttonOption = tab

      -- Can override the default handler if needed, but not recommended
      if not buttonOption.handler then
        buttonOption.handler = buttonHandler
      end
    elseif type(tab) == "string" then
      buttonOption = { text = tab, handler = buttonHandler }
    else
      error("Tab option must be a table or a string")
    end

    buttonGroupOptions.buttons[i] = buttonOption
  end

  return buttonGroupOptions
end

local function validateTabIndex(tabGroup, index)
  assertf(type(index) == "number" and index > 0 and index <= tabGroup._numTabs,
    "%s is not a valid tab index", tostring(index))
  return index
end

template:AddMethods({
  ["Refresh"] = function(self)
    self._buttonGroup:SetWidth(self:GetWidth())
    self._buttonGroup:Refresh()
  end,

  ["GetTabButton"] = function(self, index)
    if index then
      validateTabIndex(self, index)
    elseif self._selected then
      index = self._selected
    else
      return nil
    end

    return self._buttonGroup:GetButton(index)
  end,
  ["GetTabContent"] = function(self, index)
    if index then
      validateTabIndex(self, index)
    elseif self._selected then
      index = self._selected
    else
      return nil
    end

    return self._tabContent[index]
  end,
  ["GetAllTabContent"] = function(self)
    return unpack(self._tabContent)
  end,
  ["SetTabContent"] = function(self, index, content)
    assertframe(content, "content")

    local existingContent = self:GetTabContent(index)
    if existingContent then
      existingContent:ClearAllPoints()
      existingContent:Hide()
    end

    content:ClearAllPoints()
    content:Hide()
    content:SetAllPoints(self._contentFrame)

    self._tabContent[index] = content
  end,
  ["SelectTab"] = function(self, index)
    validateTabIndex(self, index)

    -- Tab did not change, take no action
    if self._selected == index then return end

    -- First, hide and release the current tab
    local content, button = self:GetTabContent(), self:GetTabButton()
    if content then content:Hide() end
    if button then button:UnlockHighlight() end

    self._selected = index

    -- Then, show and hold-open the chosen tab
    content, button = self:GetTabContent(), self:GetTabButton()
    if content then content:Show() end
    if button then button:LockHighlight() end

    self:FireCustomScriptEvent("OnTabSelect", index)
  end,
})

template:AddScripts({
  ["OnTabSelect"] = function(self, tabIndex)
    -- no-op for now
  end,
  ["OnShow"] = function(self)
    self:Refresh()
  end,
})

function template:Create(frameName, parent, options)
  options = addon:MergeOptionsTable(defaultOptions, options)
  assert(#options.tabs > 0, "TabGroup: at least one tab must be specified")

  local container = addon:CreateFrame("Frame", frameName, parent)

  local buttonGroupOptions = buildButtonGroupOptions(container, options.tabs)
  local buttonGroup = addon:CreateFrame("ButtonGroup", frameName.."Tabs", container, buttonGroupOptions)
  buttonGroup:SetPoint("TOPLEFT", container, "TOPLEFT")
  buttonGroup:SetPoint("TOPRIGHT", container, "TOPRIGHT")
  if options.tabHeight then
    buttonGroup:SetHeight(options.tabHeight)
  end

  local contentFrame = addon:CreateFrame("Frame", frameName.."Content", container)
  contentFrame:SetPoint("TOPLEFT", buttonGroup, "BOTTOMLEFT")
  contentFrame:SetPoint("TOPRIGHT", buttonGroup, "BOTTOMRIGHT")
  contentFrame:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT")
  contentFrame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT")

  container._options = options
  container._buttonGroup = buttonGroup
  container._contentFrame = contentFrame
  container._tabContent = {}
  container._numTabs = #options.tabs

  return container
end

function template:AfterCreate(group)
  if group._options.autoCreateTabContent then
    for i, _ in ipairs(group._options.tabs) do
      local content = addon:CreateFrame("Frame", nil, group)
      group:SetTabContent(i, content)
    end
  end
end