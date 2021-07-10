local _, addon = ...
local asserttype, assertf = addon.asserttype, addon.assertf
local UIParent = addon.G.UIParent

local UIDropDownMenu_Initialize = addon.G.UIDropDownMenu_Initialize
local UIDropDownMenu_SetWidth = addon.G.UIDropDownMenu_SetWidth
local UIDropDownMenu_SetText = addon.G.UIDropDownMenu_SetText
-- local UIDropDownMenu_CreateInfo = addon.G.UIDropDownMenu_CreateInfo
local UIDropDownMenu_SetSelectedValue = addon.G.UIDropDownMenu_SetSelectedValue
local UIDropDownMenu_AddButton = addon.G.UIDropDownMenu_AddButton

local template = addon:NewFrame("FormDropdown")
template:AddMixin("FormField")

template:SetDefaultOptions({
  label = "",             -- [string] Text to set above the dropdown
  labelAnchor = "LEFT",   -- [string] Where to anchor the label to the dropdown
  width = nil,            -- [number] Manual width of the dropdown's text region
  maxWidth = nil,         -- [number] Maximum allowed width of the dropdown's text region
  choices = {},           -- [table] Array of choices
  allowNil = false,       -- [boolean] Allows the selection of a nil (empty) option from the dropdown
})

-- The Blizzard dropdown functions put a large margin around dropdowns
-- I want to get rid of this large margin, so I make some adjustments to the container size/anchoring
local ddAdjust = 12

-- Adjustments to make the label look better in each anchored position
template:SetConditionalOptions("labelAnchor", {
  LEFT = {
    labelOffsetX = 14,
    labelOffsetY = 2,
    dropdownAnchor = "RIGHT",
    dropdownOffsetX = 1*ddAdjust,
    dropdownWidthAdjust = -2.5*ddAdjust,
    labelHoriz = true,
  },
  RIGHT = {
    labelOffsetX = -12,
    labelOffsetY = 2,
    dropdownAnchor = "LEFT",
    dropdownOffsetX = -1*ddAdjust,
    dropdownWidthAdjust = -1*ddAdjust,
    labelHoriz = true,
  },
  TOP = {
    labelOffsetX = 0,
    labelOffsetY = 2,
    dropdownAnchor = "BOTTOMLEFT",
    dropdownOffsetX = -1*ddAdjust,
    dropdownWidthAdjust = -2*ddAdjust,
  },
  BOTTOM = {
    labelOffsetX = 0,
    labelOffsetY = 4,
    dropdownAnchor = "TOPLEFT",
    dropdownOffsetX = -1*ddAdjust,
    dropdownWidthAdjust = -2*ddAdjust,
  },
  TOPLEFT = {
    labelOffsetX = 18,
    labelOffsetY = 2,
    dropdownAnchor = "BOTTOMLEFT",
    dropdownOffsetX = -1*ddAdjust,
    dropdownWidthAdjust = -2*ddAdjust,
  },
  TOPRIGHT = {
    labelOffsetX = -16,
    labelOffsetY = 2,
    dropdownAnchor = "BOTTOMLEFT",
    dropdownOffsetX = -1*ddAdjust,
    dropdownWidthAdjust = -2*ddAdjust,
  },
  BOTTOMLEFT = {
    labelOffsetX = 18,
    labelOffsetY = 4,
    dropdownAnchor = "TOPLEFT",
    dropdownOffsetX = -1*ddAdjust,
    dropdownWidthAdjust = -2*ddAdjust,
  },
  BOTTOMRIGHT = {
    labelOffsetX = -16,
    labelOffsetY = 4,
    dropdownAnchor = "TOPLEFT",
    dropdownOffsetX = -1*ddAdjust,
    dropdownWidthAdjust = -2*ddAdjust,
  },
  CENTER = nil, -- Not supported
})

-- Temporary fontStrings used for measurements
local testFontStrings = {}
local function getTestFontString(fontTemplate)
  local testFontString = testFontStrings[fontTemplate]

  if not testFontString then
    testFontString = UIParent:CreateFontString(nil, "BACKGROUND", fontTemplate)
    testFontStrings[fontTemplate] = testFontString
  end

  return testFontString
end

local function refreshSize(container)
  local options = container:GetOptions()
  local ddWidth = options.width

  if not ddWidth then
    -- If no width is specified, auto-resize the dropdown to fit contents
    -- Adapted from: https://medium.com/@JordanBenge/creating-a-wow-dropdown-menu-in-pure-lua-db7b2f9c0364
    local padding = 37
    ddWidth = padding
    local testFontString = getTestFontString("GameFontNormalSmall")
    for _, choice in ipairs(options.choices) do
      testFontString:SetText(choice.text)
      local strWidth = testFontString:GetStringWidth() + padding
      if strWidth > ddWidth then
        ddWidth = strWidth
      end
    end
  end

  if options.maxWidth then
    ddWidth = math.min(ddWidth, options.maxWidth)
  end

  UIDropDownMenu_SetWidth(container._dropdown, ddWidth)

  local labelWidth, labelHeight, labelOffsetX, labelOffsetY = container:GetFormLabelDimensions()
  local containerWidth, containerHeight = container._dropdown:GetSize()

  if options.labelHoriz then
    -- If the label is anchored to the left or right of the dropdown,
    -- then include the label's width and x-spacing in the container's width
    containerWidth = containerWidth + labelWidth + labelOffsetX
  else
    -- If the label is anchored above or below the dropdown,
    -- then include the label's height and y-spacing int he container's height
    containerHeight = containerHeight + labelHeight + labelOffsetY
  end

  containerWidth = containerWidth + options.dropdownWidthAdjust
  container:SetSize(containerWidth, containerHeight)
end

local function refreshChoices(container)
  local dropdown = container._dropdown
  -- The function passed to Initialize is called each time the dropdown is opened
  UIDropDownMenu_Initialize(dropdown, function()
    local currentValue = container:GetFormValue()

    for i, choice in ipairs(container:GetOptions().choices) do
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
  ["AddChoice"] = function(self, choice)
    if type(choice) == "string" then
      -- Strings can be coerced into a plain text choice
      choice = { text = choice }
    else
      asserttype(choice, "table", "choice", "FormDropdown:AddChoice")
    end

    local options = self:GetOptions()
    options.choices[#options.choices+1] = choice
  end,
  ["SetChoices"] = function(self, choices)
    asserttype(choices, "table", "choices", "FormDropdown:SetChoices")

    self:ClearChoices()
    for _, choice in ipairs(choices) do
      self:AddChoice(choice)
    end
  end,
  ["ClearChoices"] = function(self)
    self:GetOptions().choices = {}
  end,
})

template:AddScripts({
  ["OnRefresh"] = function(self)
    refreshChoices(self)
    refreshSize(self)
  end,
  ["OnFormValueChange"] = function(self, value, isUserInput)
    if isUserInput then return end

    self:Refresh()
  end,
  ["OnLabelChange"] = function(self)
    refreshSize(self)
  end,
  ["OnShow"] = function(self)
    self:Refresh()
  end,
})

function template:Create(frame, options)
  local dropdown = addon:CreateFrame("Frame", "$parentDropdown", frame, "UIDropDownMenuTemplate")
  frame:SetFormLabelParent(dropdown)

  -- The dropdown must be anchored opposite from the label, so that the container
  -- can be resized to fit the label while retaining the label's relative position to the dropdown
  local ddAnchor = options.dropdownAnchor
  dropdown:SetPoint(ddAnchor, frame, ddAnchor, options.dropdownOffsetX, 0)

  frame._dropdown = dropdown

  -- Run through SetChoices to perform validation on the list
  frame:SetChoices(options.choices)
end