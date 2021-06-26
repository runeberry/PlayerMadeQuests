local _, addon = ...

local template = addon:NewFrame("FormTextInput")
template:AddMixin("FormField")

template:SetDefaultOptions({
  label = "",               -- [string]
  labelAnchor = "TOPLEFT",
  autoFocus = false,        -- [boolean]
  textInset = 0,            -- [LRTB]
  defaultText = "",         -- [string]
  width = 200,              -- [number]

  frameTemplate = "InputBoxTemplate",
  fontTemplate = "ChatFontNormal",

  clearFocusOnEnter = true,   -- [boolean] Clears focus when Enter is pressed
  clearFocusOnEscape = true,  -- [boolean] Clears focus when Escape is pressed
  saveOnEnter = false,        -- [boolean] Saves form field when Enter is pressed
  saveOnClearFocus = true,    -- [boolean] Saves form field when focus is lost (incl. above settings)
  saveOnTextChanged = false,  -- [boolean] Saves form field whenever text is changed
})

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
  ["OnShow"] = function(self)
    self:Refresh()
  end,
})

local editBoxScripts = {
  ["OnEnterPressed"] = function(editBox)
    local options = editBox._container:GetOptions()

    if options.saveOnEnter then
      editBox._container:SetFormValue(editBox:GetText())
    end
    if options.clearFocusOnEnter then
      editBox:ClearFocus()
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

function template:Create(frame, options)
  local editBox = addon:CreateFrame("EditBox", nil, frame, options.frameTemplate)
  local insetL, insetR, insetT, insetB = addon:UnpackLRTB(options.textInset)
  editBox:SetTextInsets(insetL, insetR, insetT, insetB)
  editBox:SetAutoFocus(options.autoFocus)
  editBox:SetFontObject(options.fontTemplate)
  editBox:SetText(options.defaultText)
  addon:ApplyScripts(editBox, editBoxScripts)
  frame:SetFormLabelParent(editBox)

  local labelHeight = frame:GetFormLabel():GetHeight() + options.labelOffsetY
  local _, editBoxFontHeight = editBox:GetFont()
  editBox:SetHeight(editBoxFontHeight)
  editBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -1*labelHeight)
  editBox:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -1*labelHeight)

  -- Extra height is to account for the size of the bottom visual border
  local containerHeight = editBox:GetHeight() + labelHeight + 4
  frame:SetSize(options.width, containerHeight)

  frame._editBox = editBox
  editBox._container = frame

  return frame
end