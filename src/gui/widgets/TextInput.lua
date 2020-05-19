local _, addon = ...
local CreateFrame = addon.G.CreateFrame

local widget = addon.CustomWidgets:NewWidget("TextInput")

local labelSpacer = "  "
local textInset = 8
local scrollBarBackdrop = {
  bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
  insets = { left = -1, right = 0, top = 4, bottom = 4 }
}

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

local function widget_OnSubmit(self, fn)
  self.onSubmit = fn
end

function widget:Create(parent, labelText, editBoxText, options)
  labelText = labelText or ""
  editBoxText = editBoxText or ""

  local frame = CreateFrame("Frame", nil, parent)

  if options then
    frame.multiline = options.multiline
    frame.scrolling = options.scrolling
  end

  local label = frame:CreateFontString(nil, "BACKGROUND")
  label:SetFontObject("GameFontHighlightSmall")
  label:SetJustifyH("LEFT")
  label:SetText(labelSpacer..labelText)

  local scrollFrame, scrollBarFrame
  if frame.scrolling then
    scrollFrame, scrollBarFrame = addon:CreateScrollFrame(frame)
  end

  local editBox = CreateFrame("EditBox", nil, scrollFrame or frame)
  editBox:SetAutoFocus(false)
  editBox:SetFontObject("ChatFontNormal")
  editBox:SetText(editBoxText or "")
  editBox:SetScript("OnEscapePressed", editBox_OnEscapePressed)
  addon:ApplyBackgroundStyle(editBox)

  if frame.multiline then
    editBox:SetMultiLine(true)
  else
    -- OnSubmit will only react to single-line text boxes
    editBox:SetScript("OnEnterPressed", editBox_OnEnterPressed)
  end

  if frame.scrolling then
    local scrollBarWidth = scrollBarFrame:GetWidth()
    editBox:SetTextInsets(textInset, textInset + scrollBarWidth, textInset, textInset)

    scrollBarFrame:SetPoint("TOPRIGHT", editBox, "TOPRIGHT")
    scrollBarFrame:SetPoint("BOTTOMRIGHT", editBox, "BOTTOMRIGHT")
    scrollFrame:SetPoint("TOPLEFT", label, "BOTTOMLEFT")
    scrollFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT")
    scrollFrame:SetPoint("TOPRIGHT", label, "BOTTOMRIGHT", -1*scrollBarWidth, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1*scrollBarWidth, 0)

    scrollFrame:SetScrollChild(editBox)
  else
    editBox:SetTextInsets(textInset, textInset, textInset, textInset)
  end

  label:SetPoint("TOPLEFT", frame, "TOPLEFT")
  editBox:SetPoint("TOPLEFT", label, "BOTTOMLEFT")
  editBox:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT")
  editBox:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")

  -- These are simply default heights and can be modified after the widget is created
  if frame.multiline then
    frame:SetHeight(getFontHeight(label) + getFontHeight(editBox)*3 + textInset*2)
  else
    frame:SetHeight(getFontHeight(label) + getFontHeight(editBox) + textInset*2)
  end


  editBox._widget = frame
  frame.label = label
  frame.editBox = editBox

  frame.clearFocusOnEnter = true
  frame.clearFocusOnEscape = true

  frame.SetEnabled = widget_SetEnabled
  frame.SetLabel = widget_SetLabel
  frame.SetText = widget_SetText
  frame.GetText = widget_GetText
  frame.OnSubmit = widget_OnSubmit

  return frame
end