local _, addon = ...
local asserttype, assertf = addon.asserttype, addon.assertf

local UIDropDownMenu_Initialize = addon.G.UIDropDownMenu_Initialize
local UIDropDownMenu_SetWidth = addon.G.UIDropDownMenu_SetWidth
local UIDropDownMenu_SetText = addon.G.UIDropDownMenu_SetText
-- local UIDropDownMenu_CreateInfo = addon.G.UIDropDownMenu_CreateInfo
local UIDropDownMenu_SetSelectedValue = addon.G.UIDropDownMenu_SetSelectedValue
local UIDropDownMenu_AddButton = addon.G.UIDropDownMenu_AddButton

local widget = addon:NewFrame("DataDropdown")

local defaultOptions = {
  text = "",        -- [string] Text to set above the dropdown
  width = nil,      -- [number] Manual width of the dropdown's text region
  maxWidth = nil,   -- [number] Maximum allowed width of the dropdown's text region
  choices = {},     -- [table] Array of choices
  allowNil = false, -- [boolean]

  autoLoad = true,  -- [boolean] If true, the widget will be refreshed immediately
  get = nil,        -- [function() -> number] Getter to load the value
  set = nil,        -- [function(number, string)] Setter to save the value
}

local function refreshDropdownWidth(dropdown)
  local options, label = dropdown._options, dropdown._label
  local width = options.width

  if not width then
    -- If no width is specified, auto-resize the dropdown to fit contents
    -- Adapted from: https://medium.com/@JordanBenge/creating-a-wow-dropdown-menu-in-pure-lua-db7b2f9c0364
    local padding = 37
    width = padding
    for _, choice in ipairs(options.choices) do
      -- Borrow the label fontString for a sec so we can do some measuring
      label:SetText(choice.text)
      local strWidth = label:GetStringWidth() + padding
      if strWidth > width then
        width = strWidth
      end
    end
    -- Done measuring, put the label text back
    label:SetText(options.text)
  end

  if options.maxWidth then
    width = math.min(width, options.maxWidth)
  end

  UIDropDownMenu_SetWidth(dropdown, width)
end

local function refreshChoices(dropdown)
  -- The function passed to Initialize is called each time the dropdown is opened
  UIDropDownMenu_Initialize(dropdown, function()
    local currentValue = dropdown:GetValue()

    for i, choice in ipairs(dropdown._options.choices) do
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
          dropdown:SetValue(i)
        end
      end

      -- Supported options can be found here: https://wow.gamepedia.com/API_UIDropDownMenu_AddButton
      UIDropDownMenu_AddButton(choice)
    end
  end)
end

local function getValidatedChoice(dropdown, index)
  local choice

  if index == nil and dropdown._options.allowNil then
    -- nil must be explicitly allowed
  else
    asserttype(index, "number", "index", "DataDropdown:SetSelected")
    choice = dropdown._options.choices[index]
    assertf(choice, "%i is not a valid selection for this dropdown", index)
  end

  return choice
end

local methods = {
  ["Refresh"] = function(self)
    refreshChoices(self)
    refreshDropdownWidth(self)
  end,
  ["GetValue"] = function(self)
    local index = self._options.get()
    return index, getValidatedChoice(self, index)
  end,
  ["SetValue"] = function(self, index)
    local choice = getValidatedChoice(self, index)
    self._options.set(index, choice)
    return choice
  end,

  ["SetText"] = function(self, text)
    self._label:SetText(text)
  end,
  ["AddChoice"] = function(self, choice)
    if type(choice) == "string" then
      -- Strings can be coerced into a plain text choice
      choice = { text = choice }
    else
      asserttype(choice, "table", "choice", "DataDropdown:AddChoice")
    end

    self._options.choices[#self._options.choices+1] = choice
  end,
  ["SetChoices"] = function(self, choices)
    asserttype(choices, "table", "choices", "DataDropdown:SetChoices")

    self:ClearChoices()
    for _, choice in ipairs(choices) do
      self:AddChoice(choice)
    end
  end,
  ["ClearChoices"] = function(self)
    self._options.choices = {}
  end,
}

local scripts = {
  ["OnShow"] = function(self)
    self:Refresh()
  end,
}

function widget:Create(frameName, parent, options)
  options = addon:MergeOptionsTable(defaultOptions, options)
  asserttype(options.get, "function", "options.get", "DataDropdown:Create")
  asserttype(options.set, "function", "options.set", "DataDropdown:Create")

  local dropdown = addon:CreateFrame("Frame", frameName, parent, "UIDropDownMenuTemplate")

  local label = dropdown:CreateFontString(dropdown, "BACKGROUND", "GameFontNormalSmall")
  label:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 20, 2)
  label:SetText(options.text)

  dropdown._options = options
  dropdown._label = label

  addon:ApplyMethods(dropdown, methods)
  addon:ApplyScripts(dropdown, scripts)

  -- Run through SetChoices to perform validation on the list
  dropdown:SetChoices(options.choices)

  if options.autoLoad then
    dropdown:Refresh()
  end

  return dropdown
end