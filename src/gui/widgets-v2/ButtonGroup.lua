local _, addon = ...
local asserttype, assertf, assertframe = addon.asserttype, addon.assertf, addon.assertframe
local PanelTemplates_TabResize = addon.G.PanelTemplates_TabResize

local template = addon:NewFrame("ButtonGroup", "FlowLayout")

template:SetDefaultOptions({
  -- buttonTemplate = "OptionsFrameTabButtonTemplate",
  template = "UIPanelButtonTemplate",
  sizeMode = "fit",           -- [string] Options are: "fit" (default), "flex", "tab"

  margin = 0,                 -- [LRTB] Space between buttons and edge of containing group
  padding = 8,                -- [LRTB] Space between the text inside the button and the edge of the button
  spacing = 0,                -- [number] Space between buttons

  anchor = "LEFT",            -- [string] Side anchor where the buttons will start growing from

  buttons = {}                -- [table] Button info, see below
})

local defaultButtonOptions = {
  text = " ",                 -- [string] Button text
  handler = function() end,   -- [function] "OnClick" handler
  width = nil,                -- [number] Default: text width + padding
  height = nil,               -- [number] Default: text height + padding
  flexParams = { flex = 1 },  -- [table] Params to calculate flex width, if sizeMode == "flex"

  -- These values will use the group's options unless overriden
  template = nil,
  padding = nil,
}

local function addButton(group, buttonOptions)
  local groupOptions = group:GetOptions()
  buttonOptions = addon:MergeOptionsTable(groupOptions, defaultButtonOptions, buttonOptions)
  local index = #group._buttons+1

  local buttonName = string.format("%sButton%i", group:GetName(), index)
  local button = addon:CreateFrame("Button", buttonName, group, buttonOptions.template)
  button:SetText(buttonOptions.text or " ")
  button:SetScript("OnClick", function()
    addon:catch(buttonOptions.handler, button)
  end)

  group:AddContent(button, { inline = true })

  button._options = buttonOptions

  group._buttons[index] = button
end

local function calcButtonSize(button)
  local options = button._options

  local pL, pR, pT, pB = addon:UnpackLRTB(options.padding)
  local width, height = options.width, options.height -- Explicit options take priority

  if not width then
    width = button:GetTextWidth() + pL + pR
  end

  if not height then
    height = button:GetTextHeight() + pT + pB
  end

  return width, height
end

local function isGroupHorizontal(group)
  local options = group:GetOptions()
  return options.anchor == "LEFT" or options.anchor == "RIGHT"
end

local function refreshButtonsFlexFill(group)
  local groupWidth, groupHeight = group:GetSize()
  if groupWidth == 0 or groupHeight == 0 then return end -- can't calculate

  local groupOptions = group:GetOptions()
  local isHorizontal = isGroupHorizontal(group)
  local buttonSizes = {}
  local allFlexParams = {}

  -- First, grab the flex-sizing params from each button
  for i, button in ipairs(group._buttons) do
    local buttonOptions = button._options
    local flexParams = buttonOptions.flexParams

    -- Given the button's options and text, calculate its target size
    local buttonSize = { calcButtonSize(button) }
    buttonSizes[i] = buttonSize

    if not flexParams.size and not flexParams.min then
      -- If no minimum bound is specified, calculate it based on the button's text
      if isHorizontal then
        flexParams.min = buttonSize[1]
      else
        flexParams.min = buttonSize[2]
      end
    end

    allFlexParams[#allFlexParams+1] = flexParams
  end

  -- Then, calculate the flex sizes for each button in the group
  local l, r, t, b = addon:UnpackLRTB(groupOptions.margin)
  local sp = groupOptions.spacing
  local n = #group._buttons
  local flexMargin = (isHorizontal and (l + r)) or (t + b)
  local flexMax = (isHorizontal and groupWidth) or groupHeight

  local flexWidth = flexMax - flexMargin - (sp*(n-1))

  -- Finally, calculate the flex sizes...
  local flexResults = addon:CalculateFlex(flexWidth, allFlexParams)

  -- ...and apply the results
  for i, button in ipairs(group._buttons) do
    local width, height = buttonSizes[i][1], buttonSizes[i][2]
    if isHorizontal then
      button:SetSize(flexResults[i], height)
    else
      button:SetSize(width, flexResults[i])
    end
  end
end

local function refreshButtonsTab(group)
  for _, button in ipairs(group._buttons) do
    -- todo: this doesn't respect the parent container's width
    -- but I don't quite understand which width parameters to pass
    -- See source code here: https://github.com/Gethe/wow-ui-source/blob/classic/SharedXML/SharedUIPanelTemplates.lua#L446
    PanelTemplates_TabResize(button, -8)
  end
end

local function refreshButtonsStandard(group)
  for _, button in ipairs(group._buttons) do
    local width, height = calcButtonSize(button)
    button:SetSize(width, height)
  end
end

template:AddMethods({
  ["AddButton"] = function(self, buttonOptions)
    asserttype(buttonOptions, "table", "buttonOptions", "ButtonGroup:AddButton")

    addButton(self, buttonOptions)
  end,
  ["GetButton"] = function(self, index)
    asserttype(index, "number", "index", "ButtonGroup:GetButton")

    local button = self._buttons[index]
    assertf(button, "No button exists at index %i", index)

    return button
  end,
})

template:AddScripts({
  ["OnRefresh"] = function(self)
    local sizeMode = self:GetOptions().sizeMode

    if sizeMode == "flex" then
      refreshButtonsFlexFill(self)
    elseif sizeMode == "tab" then
      refreshButtonsTab(self)
    else
      refreshButtonsStandard(self)
    end

    for _, button in ipairs(self._buttons) do
      -- (jb, 5/15/21) Unusual behavior, sometimes the last button in a group
      -- will just disappear from screen after resizing, though the API indicates
      -- the button is still visible and shown!
      -- Calling the button's width seems to fix this.
      button:GetWidth()
    end
  end,
})

function template:Create(frame, options)
  addon:ValidateSide(options.anchor)

  frame._buttons = {}

  for _, buttonOptions in ipairs(options.buttons) do
    addButton(frame, buttonOptions)
  end
end