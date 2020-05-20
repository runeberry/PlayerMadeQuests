local _, addon = ...
local CreateFrame = addon.G.CreateFrame

local widget = addon.CustomWidgets:NewWidget("TextInput")

local labelSpacer = "  "
local textInset = 8

local function getFontHeight(fontInstance)
  local _, height = fontInstance:GetFont()
  return math.floor(height+0.5)
end

local function editBox_OnEnterPressed(editBox)
  local parent = editBox._widget
  if parent.onSubmit then
    parent.onSubmit(parent:GetText())
  end
  if parent.clearFocusOnEnter then
    editBox:ClearFocus()
  end
end

local function editBox_OnEscapePressed(editBox)
  if editBox._widget.clearFocusOnEscape then
    editBox:ClearFocus()
  end
end

local function widget_SetEnabled(self, flag)
  self.editBox:SetEnabled(flag or true)
end

local function widget_SetLabel(self, text)
  text = text or ""
  self.label:SetText(labelSpacer..text)
end

local function widget_SetText(self, text)
  self.editBox:SetText(text or "")
end

local function widget_GetText(self)
  return self.editBox:GetText()
end

local function widget_OnEnterPressed(self, fn)
  self.onSubmit = fn
end

function widget:Create(parent, labelText, editBoxText, multiline)
  labelText = labelText or ""
  editBoxText = editBoxText or ""

  local frame = CreateFrame("Frame", nil, parent)

  local label = frame:CreateFontString(nil, "BACKGROUND")
  label:SetFontObject("GameFontHighlightSmall")
  label:SetJustifyH("LEFT")
  label:SetText(labelSpacer..labelText)

  local editBox = CreateFrame("EditBox", nil, frame)
  editBox:SetAutoFocus(false)
  editBox:SetFontObject("ChatFontNormal")
  editBox:SetText(editBoxText or "")
  editBox:SetScript("OnEscapePressed", editBox_OnEscapePressed)
  editBox:SetTextInsets(textInset, textInset, textInset, textInset)
  addon:ApplyBackgroundStyle(editBox)

  if multiline then
    editBox:SetMultiLine(true)
  else
    -- OnSubmit will only react to single-line text boxes
    editBox:SetScript("OnEnterPressed", editBox_OnEnterPressed)
  end

  label:SetPoint("TOPLEFT", frame, "TOPLEFT")
  editBox:SetPoint("TOPLEFT", label, "BOTTOMLEFT")
  editBox:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT")
  editBox:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")

  local textHeight = getFontHeight(editBox)
  if multiline then
    textHeight = textHeight * 3
  end
  frame:SetHeight(getFontHeight(label) + textHeight + textInset*2)

  editBox._widget = frame
  frame.label = label
  frame.editBox = editBox

  frame.clearFocusOnEnter = true
  frame.clearFocusOnEscape = true

  frame.SetEnabled = widget_SetEnabled
  frame.SetLabel = widget_SetLabel
  frame.SetText = widget_SetText
  frame.GetText = widget_GetText
  frame.OnEnterPressed = widget_OnEnterPressed

  return frame
end