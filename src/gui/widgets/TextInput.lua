local _, addon = ...
local CreateFrame = addon.G.CreateFrame

local widget = addon.CustomWidgets:NewWidget("TextInput")

local labelSpacer = "  "
local textInset = 8

local function getFontHeight(fontInstance)
  local _, height = fontInstance:GetFont()
  return math.floor(height+0.5)
end

local singleLineEditBoxScripts = {
  ["OnEnterPressed"] = function(editBox)
    local parent = editBox._widget
    -- OnSubmit will only react to single-line text boxes
    if parent.onSubmit then
      parent.onSubmit(parent:GetText())
    end
    if parent.clearFocusOnEnter then
      editBox:ClearFocus()
    end
  end
}

local editBoxScripts = {
  ["OnEscapePressed"] = function (editBox)
    if editBox._widget.clearFocusOnEscape then
      editBox:ClearFocus()
    end
  end,
  ["OnTextChanged"] = function(editBox, isUserInput)
    if isUserInput then
      editBox._widget.isDirty = true
    end
  end
}

local widgetMethods = {
  ["GetText"] = function(self)
    return self.editBox:GetText()
  end,
  ["IsDirty"] = function(self)
    return self.isDirty or false
  end,
  ["SetDirty"] = function(self, bool)
    self.isDirty = bool
  end,
  ["SetEnabled"] = function(self, flag)
    if flag == nil then flag = true end
    self.editBox:SetEnabled(flag)
  end,
  ["SetLabel"] = function(self, text)
    text = text or ""
    self.label:SetText(labelSpacer..text)
  end,
  ["SetText"] = function(self, text)
    self.editBox:SetText(text or "")
  end
}

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
  editBox:SetTextInsets(textInset, textInset, textInset, textInset)
  addon.CustomWidgets:ApplyScripts(frame, editBox, editBoxScripts)
  addon:ApplyBackgroundStyle(editBox)
  if multiline then
    editBox:SetMultiLine(true)
  else
    -- Don't want to mess with the OnEnter behavior of a multiline editbox
    addon.CustomWidgets:ApplyScripts(frame, editBox, singleLineEditBoxScripts)
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
  frame.multiline = multiline

  frame.clearFocusOnEnter = true
  frame.clearFocusOnEscape = true

  for name, fn in pairs(widgetMethods) do
    frame[name] = fn
  end

  return frame
end