local _, addon = ...

local template = addon:NewFrame("FormTextInput")

local defaultOptions = {
  label = "",               -- [string]
  autoFocus = false,        -- [boolean]
  textInset = 0,            -- [LRTB]
  defaultText = "",         -- [string]
  width = 200,              -- [number]

  frameTemplate = "InputBoxTemplate",
  fontTemplate = "ChatFontNormal",
  labelFontTemplate = "GameFontHighlightSmall",
  labelJustifyH = "LEFT",

  clearFocusOnEnter = true,   -- [boolean] Clears focus when Enter is pressed
  clearFocusOnEscape = true,  -- [boolean] Clears focus when Escape is pressed
  saveOnEnter = false,        -- [boolean] Saves form field when Enter is pressed
  saveOnClearFocus = true,    -- [boolean] Saves form field when focus is lost (incl. above settings)
  saveOnTextChanged = false,  -- [boolean] Saves form field whenever text is changed
}

template:AddMethods({
  ["Refresh"] = function(self)
    self._editBox:SetText(self:GetFormValue())
  end,
  ["SetText"] = function(self, text)
    self._editBox:SetText(self, text or "")
  end,
  ["SetLabel"] = function(self, text)
    self._label:SetText(text or "")
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

local editBoxScripts = {
  ["OnEnterPressed"] = function(editBox)
    local options = editBox._container._options

    if options.saveOnEnter then
      editBox._container:SetFormValue(editBox:GetText())
    end
    if options.clearFocusOnEnter then
      editBox:ClearFocus()
    end
  end,
  ["OnEscapePressed"] = function(editBox)
    if editBox._container._options.clearFocusOnEscape then
      editBox:ClearFocus()
    end
  end,
  ["OnEditFocusLost"] = function(editBox)
    editBox:HighlightText(0, 0)

    if editBox._container._options.saveOnClearFocus then
      editBox._container:SetFormValue(editBox:GetText())
    end
  end,
  ["OnTextChanged"] = function(editBox, isUserInput)
    if not isUserInput then return end
    if editBox._container._options.saveOnTextChanged then
      editBox._container:SetFormValue(editBox:GetText())
    end
  end,
}

function template:Create(frameName, parent, options)
  options = addon:MergeOptionsTable(defaultOptions, options)

  local container = addon:CreateFrame("Frame", frameName, parent)

  local editBox = addon:CreateFrame("EditBox", frameName.."EditBox", container, options.frameTemplate)
  local insetL, insetR, insetT, insetB = addon:UnpackLRTB(options.textInset)
  editBox:SetTextInsets(insetL, insetR, insetT, insetB)
  editBox:SetAutoFocus(options.autoFocus)
  editBox:SetFontObject(options.fontTemplate)
  editBox:SetText(options.defaultText)
  addon:ApplyScripts(editBox, editBoxScripts)

  local labelSpacing = 4
  local labelOpts = {
    text = options.label,
    anchor = "TOPLEFT",
    offsetY = labelSpacing
  }
  local label = addon:CreateFrame("FormLabel", frameName.."Label", editBox, labelOpts)

  local labelHeight = label:GetHeight() + labelSpacing
  local _, editBoxFontHeight = editBox:GetFont()
  editBox:SetHeight(editBoxFontHeight)
  editBox:SetPoint("TOPLEFT", container, "TOPLEFT", 6, -1*labelHeight)
  editBox:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, -1*labelHeight)

  -- Extra height is to account for the size of the bottom visual border
  local containerHeight = editBox:GetHeight() + labelHeight + 4
  container:SetSize(options.width, containerHeight)

  addon:ApplyFormFieldMethods(container, template)

  container._options = options
  container._editBox = editBox
  container._label = label
  editBox._container = container

  return container
end