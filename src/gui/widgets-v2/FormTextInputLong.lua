local _, addon = ...

local template = addon:NewFrame("FormTextInputLong")
template:AddMixin("FormField")

template:SetDefaultOptions({
  label = "",               -- [string]
  labelAnchor = "TOPLEFT",  -- [string]
  lines = 3,                -- [number]
  autoFocus = false,        -- [boolean]
  textInset = 6,            -- [LRTB]
  defaultText = "",         -- [string]

  defaultWidth = 200,

  frameTemplate = "InputBoxTemplate",
  fontTemplate = "ChatFontNormal",
  labelFontTemplate = "GameFontHighlightSmall",

  clearFocusOnEscape = true,  -- [boolean] Clears focus when Escape is pressed
  saveOnClearFocus = true,    -- [boolean] Saves form field when focus is lost (incl. above settings)
  saveOnTextChanged = false,  -- [boolean] Saves form field whenever text is changed
})

local function refreshSize(frame)
  local options = frame:GetOptions()
  local editBox, scrollFrame, editBoxBorderFrame = frame._editBox, frame._scrollFrame, frame._editBoxBorderFrame

  -- The container must be tall enough to contain the label
  local _, labelHeight, _, labelOffsetY = frame:GetFormLabelDimensions()
  local _, lineHeight = editBox:GetFont()
  local lineSpacing = editBox:GetSpacing()
  local il, ir, it, ib = addon:UnpackLRTB(options.textInset)
  local containerHeight =             -- Container must be tall enough to show the specified # lines
    (lineHeight * options.lines) +    -- Height of text * number of lines to be shown
    (lineSpacing * options.lines) +   -- Total height of spacing between lines, leaving extra space at bottom
    2 +                               -- Small buffer so the box doesn't scroll on the last line
    it + ib +                         -- Vertical text insets
    labelHeight + labelOffsetY        -- Height of the label above the editBox border

  frame:SetHeight(containerHeight)

  -- The editBox border must be anchored low enough to not overlap with the label
  editBoxBorderFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -1*labelHeight)
  editBoxBorderFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")

  -- The scroll frame must be inset within the editBox border frame
  scrollFrame:SetPoint("TOPLEFT", editBoxBorderFrame, "TOPLEFT", il, -1*it)
  scrollFrame:SetPoint("BOTTOMRIGHT", editBoxBorderFrame, "BOTTOMRIGHT", -1*ir, ib)

  -- When the mouse wheel is scrolled, scroll the text by one line
  scrollFrame._scrollHeight = lineHeight + lineSpacing
end

template:AddMethods({
  ["SetText"] = function(self, text)
    self._editBox:SetText(text or "")
  end,
})

template:AddScripts({
  ["OnRefresh"] = function(self)
    self:SetText(self:GetFormValue())
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
  ["OnSizeChanged"] = function(self, width, height)
    -- The editBox must match the width of the scrollFrame without anchoring to it
    -- because the scrollFrame's anchors seem to get altered when it scrolls.
    -- It looks like the editBox gets anchored to scrollFrame automatically by
    -- becoming its scrollChild, so we just need to set width.
    local il, ir, it, ib = addon:UnpackLRTB(self:GetOptions().textInset)
    self._editBox:SetWidth(width - il - ir)
  end,
})

local editBoxScripts = {
  ["OnCursorChanged"] = function(editBox, xPos, yPos, _, lineHeight)
    -- Cool formula, but I don't need it right now
    -- local lineNum = math.floor((-1*yPos / lineHeight) + 0.5) + 1

    local scrollFrame = editBox._container._scrollFrame
    local vs = scrollFrame:GetVerticalScroll()
    local h = scrollFrame:GetHeight()

    yPos = -1*yPos -- Easier to work with a positive yPos
    if yPos + lineHeight > vs + h then
      -- Cursor is below the visible area
      local scroll = math.ceil(yPos + lineHeight - h)
      scrollFrame:SetVerticalScroll(scroll)
    elseif yPos < vs then
      -- Cursor is above the visible area
      local scroll = yPos
      scrollFrame:SetVerticalScroll(scroll)
    end
  end,
  ["OnEscapePressed"] = function(editBox)
    local options = editBox._container:GetOptions()
    if options.clearFocusOnEscape then
      editBox:ClearFocus()
    end
  end,
  ["OnEditFocusLost"] = function(editBox)
    editBox:HighlightText(0, 0)

    local options = editBox._container:GetOptions()
    if options.saveOnClearFocus then
      editBox._container:SetFormValue(editBox:GetText())
    end
  end,
  ["OnTextChanged"] = function(editBox, isUserInput)
    if not isUserInput then return end
    local options = editBox._container:GetOptions()
    if options.saveOnTextChanged then
      editBox._container:SetFormValue(editBox:GetText())
    end
  end,
}

-- This will place the cursor at the end of the editBox text whenever you click
-- inside the editBox border, but within an area that the editBox hasn't expanded to yet
local function EBBF_OnClick(self)
  local editBox = self._container._editBox
  editBox:SetFocus()
  editBox:HighlightText(0, 0)
  editBox:SetCursorPosition(#(editBox:GetText()))
end

local function SF_OnMouseWheel(self, delta)
  local newValue = self:GetVerticalScroll() - (delta * self._scrollHeight);

  if (newValue < 0) then
    newValue = 0;
  elseif (newValue > self:GetVerticalScrollRange()) then
    newValue = self:GetVerticalScrollRange();
  end

  self:SetVerticalScroll(newValue)
end

function template:Create(frame, options)
  -- This border frame is a Button so that we can add a click handler
  local editBoxBorderFrame = addon:CreateFrame("Button", "$parentBorderFrame", frame)
  addon:ApplyBackgroundStyle(editBoxBorderFrame)
  editBoxBorderFrame:SetScript("OnClick", EBBF_OnClick)
  frame:SetFormLabelParent(editBoxBorderFrame)

  local scrollFrame = addon:CreateFrame("ScrollFrame", nil, editBoxBorderFrame)
  scrollFrame:SetScript("OnMouseWheel", SF_OnMouseWheel)

  local editBox = addon:CreateFrame("EditBox", nil, scrollFrame)
  editBox:SetMultiLine(true)
  editBox:SetAutoFocus(options.autoFocus)
  editBox:SetFontObject(options.fontTemplate)
  editBox:SetText(options.defaultText)
  addon:ApplyScripts(editBox, editBoxScripts)
  scrollFrame:SetScrollChild(editBox)

  frame._editBoxBorderFrame = editBoxBorderFrame
  frame._scrollFrame = scrollFrame
  frame._editBox = editBox
  editBox._container = frame
  editBoxBorderFrame._container = frame
  scrollFrame._scrollHeight = 1

  refreshSize(frame)
end