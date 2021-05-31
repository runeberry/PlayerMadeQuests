local _, addon = ...
local asserttype, assertf = addon.asserttype, addon.assertf

local UIDropDownMenu_Initialize = addon.G.UIDropDownMenu_Initialize
local UIDropDownMenu_SetWidth = addon.G.UIDropDownMenu_SetWidth
local UIDropDownMenu_SetText = addon.G.UIDropDownMenu_SetText
-- local UIDropDownMenu_CreateInfo = addon.G.UIDropDownMenu_CreateInfo
local UIDropDownMenu_SetSelectedValue = addon.G.UIDropDownMenu_SetSelectedValue
local UIDropDownMenu_AddButton = addon.G.UIDropDownMenu_AddButton

local template = addon:NewFrame("FormDropdown")

local defaultOptions = {
  label = "",             -- [string] Text to set above the dropdown
  labelAnchor = "LEFT",   -- [string] Where to anchor the label to the dropdown
  width = nil,            -- [number] Manual width of the dropdown's text region
  maxWidth = nil,         -- [number] Maximum allowed width of the dropdown's text region
  choices = {},           -- [table] Array of choices
  allowNil = false,       -- [boolean] Allows the selection of a nil (empty) option from the dropdown

  autoLoad = true,        -- [boolean] If true, the widget will be refreshed immediately
}

-- The Blizzard dropdown functions put a large margin around dropdowns
-- I want to get rid of this large margin, so I make some adjustments to the container size/anchoring
local ddAdjust = 12

-- Adjustments to make the label look better in each anchored position
local labelAnchorOptions = {
  LEFT = {
    offsetX = 14,
    offsetY = 2,
    dropdownAnchor = "RIGHT",
    dropdownOffsetX = 1*ddAdjust,
    dropdownWidthAdjust = -2.5*ddAdjust,
    labelHoriz = true,
  },
  RIGHT = {
    offsetX = -12,
    offsetY = 2,
    dropdownAnchor = "LEFT",
    dropdownOffsetX = -1*ddAdjust,
    dropdownWidthAdjust = -1*ddAdjust,
    labelHoriz = true,
  },
  TOP = {
    offsetX = 0,
    offsetY = 2,
    dropdownAnchor = "BOTTOMLEFT",
    dropdownOffsetX = -1*ddAdjust,
    dropdownWidthAdjust = -2*ddAdjust,
  },
  BOTTOM = {
    offsetX = 0,
    offsetY = 4,
    dropdownAnchor = "TOPLEFT",
    dropdownOffsetX = -1*ddAdjust,
    dropdownWidthAdjust = -2*ddAdjust,
  },
  TOPLEFT = {
    offsetX = 18,
    offsetY = 2,
    dropdownAnchor = "BOTTOMLEFT",
    dropdownOffsetX = -1*ddAdjust,
    dropdownWidthAdjust = -2*ddAdjust,
  },
  TOPRIGHT = {
    offsetX = -16,
    offsetY = 2,
    dropdownAnchor = "BOTTOMLEFT",
    dropdownOffsetX = -1*ddAdjust,
    dropdownWidthAdjust = -2*ddAdjust,
  },
  BOTTOMLEFT = {
    offsetX = 18,
    offsetY = 4,
    dropdownAnchor = "TOPLEFT",
    dropdownOffsetX = -1*ddAdjust,
    dropdownWidthAdjust = -2*ddAdjust,
  },
  BOTTOMRIGHT = {
    offsetX = -16,
    offsetY = 4,
    dropdownAnchor = "TOPLEFT",
    dropdownOffsetX = -1*ddAdjust,
    dropdownWidthAdjust = -2*ddAdjust,
  },
  CENTER = nil, -- Not supported
}

local function refreshSize(container)
  local options, label = container._options, container._label:GetFontString()
  local ddWidth = options.width

  if not ddWidth then
    -- If no width is specified, auto-resize the dropdown to fit contents
    -- Adapted from: https://medium.com/@JordanBenge/creating-a-wow-dropdown-menu-in-pure-lua-db7b2f9c0364
    local padding = 37
    ddWidth = padding
    for _, choice in ipairs(options.choices) do
      -- Borrow the label fontString for a sec so we can do some measuring
      label:SetText(choice.text)
      local strWidth = label:GetStringWidth() + padding
      if strWidth > ddWidth then
        ddWidth = strWidth
      end
    end
    -- Done measuring, put the label text back
    label:SetText(options.label)
  end

  if options.maxWidth then
    ddWidth = math.min(ddWidth, options.maxWidth)
  end

  UIDropDownMenu_SetWidth(container._dropdown, ddWidth)

  local containerWidth, containerHeight = container._dropdown:GetSize()

  local lao = labelAnchorOptions[options.labelAnchor]
  if lao.labelHoriz then
    -- If the label is anchored to the left or right of the dropdown,
    -- then include the label's width and x-spacing in the container's width
    containerWidth = containerWidth + lao.offsetX + label:GetWidth()
  else
    -- If the label is anchored above or below the dropdown,
    -- then include the label's height and y-spacing int he container's height
    containerHeight = containerHeight + lao.offsetY + label:GetHeight()
  end

  containerWidth = containerWidth + lao.dropdownWidthAdjust
  container:SetSize(containerWidth, containerHeight)
end

local function refreshChoices(container)
  local dropdown = container._dropdown
  -- The function passed to Initialize is called each time the dropdown is opened
  UIDropDownMenu_Initialize(dropdown, function()
    local currentValue = container:GetFormValue()

    for i, choice in ipairs(container._options.choices) do
      choice.checked = i == currentValue

      -- This "func" is run whenever a choice is selected
      choice.func = function(c)
        -- c is the selected choice, and c.value == choice.text
        UIDropDownMenu_SetSelectedValue(dropdown, c.value, c.value)
        UIDropDownMenu_SetText(dropdown, c.value)
        c.checked = true

        -- Only set the value if it's changed
        if i ~= currentValue then
          -- The "choice" value will be passed to the data setter, not "c"
          container:SetFormValue(i, false)
        end
      end

      -- Supported options can be found here: https://wow.gamepedia.com/API_UIDropDownMenu_AddButton
      UIDropDownMenu_AddButton(choice)
    end
  end)
end

template:AddMethods({
  ["Refresh"] = function(self)
    refreshChoices(self)
    refreshSize(self)
  end,
  ["SetText"] = function(self, text)
    self._label:SetText(text)
  end,
  ["AddChoice"] = function(self, choice)
    if type(choice) == "string" then
      -- Strings can be coerced into a plain text choice
      choice = { text = choice }
    else
      asserttype(choice, "table", "choice", "FormDropdown:AddChoice")
    end

    self._options.choices[#self._options.choices+1] = choice
  end,
  ["SetChoices"] = function(self, choices)
    asserttype(choices, "table", "choices", "FormDropdown:SetChoices")

    self:ClearChoices()
    for _, choice in ipairs(choices) do
      self:AddChoice(choice)
    end
  end,
  ["ClearChoices"] = function(self)
    self._options.choices = {}
  end,
})

template:AddScripts({
  ["OnFormValueChange"] = function(self, value, isUserInput)
    if isUserInput then return end

    self:Refresh()
  end,
  ["OnShow"] = function(self)
    self:Refresh()
  end,
})

function template:Create(frameName, parent, options)
  options = addon:MergeOptionsTable(defaultOptions, options)
  asserttype(options.labelAnchor, "string", "options.labelAnchor", "FormDropdown:Create")

  local container = addon:CreateFrame("Frame", frameName, parent)

  local dropdown = addon:CreateFrame("Frame", frameName.."Dropdown", container, "UIDropDownMenuTemplate")


  local labelOpts = labelAnchorOptions[options.labelAnchor]
  labelOpts.anchor = options.labelAnchor
  labelOpts.text = options.label
  local label = addon:CreateFrame("FormLabel", frameName.."Label", dropdown, labelOpts)

  -- The dropdown must be anchored opposite from the label, so that the container
  -- can be resized to fit the label while retaining the label's relative position to the dropdown
  local ddAnchor = labelOpts.dropdownAnchor
  dropdown:SetPoint(ddAnchor, container, ddAnchor, labelOpts.dropdownOffsetX, 0)

  addon:ApplyFormFieldMethods(container, template)

  container._options = options
  container._dropdown = dropdown
  container._label = label

  return container
end

function template:AfterCreate(container)
  -- Run through SetChoices to perform validation on the list
  container:SetChoices(container._options.choices)

  if container._options.autoLoad then
    container:Refresh()
  end
end