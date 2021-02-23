local _, addon = ...

local template = addon:NewFrame("FormTextInput")

local defaultOptions = {
  label = "",               -- [string]
  multiline = false,        -- [boolean]
  autoFocus = false,        -- [boolean]
  textInset = 0,            -- [LRTB]
  defaultText = "",         -- [string]
  width = 100,              -- [number]

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
    self:SetText(self:GetFormValue())
  end,
  ["SetLabel"] = function(self, text)
    self._label:SetText(text or "")
  end,
})

template:AddScripts({
  ["OnEnterPressed"] = function(self)
    local options = self._options

    -- Don't mess with the Enter behavior of a multiline EditBox
    if options.multiline then return end

    if options.saveOnEnter then
      self:SetFormValue(self:GetText())
    end
    if options.clearFocusOnEnter then
      self:ClearFocus()
    end
  end,
  ["OnEscapePressed"] = function(self)
    if self._options.clearFocusOnEscape then
      self:ClearFocus()
    end
  end,
  ["OnEditFocusLost"] = function(self)
    self:HighlightText(0, 0)

    if self._options.saveOnClearFocus then
      self:SetFormValue(self:GetText())
    end
  end,
  ["OnTextChanged"] = function(self, isUserInput)
    if not isUserInput then return end
    if self._options.saveOnTextChanged then
      self:SetFormValue(self:GetText())
    end
  end,

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

  local editBox = addon:CreateFrame("EditBox", frameName, parent, options.frameTemplate)
  editBox:SetAutoFocus(options.autoFocus)
  editBox:SetFontObject(options.fontTemplate)
  editBox:SetMultiLine(options.multiline)
  editBox:SetText(options.defaultText)

  local insetL, insetR, insetT, insetB = addon:UnpackLRTB(options.textInset)
  editBox:SetTextInsets(insetL, insetR, insetT, insetB)

  -- local _, height = editBox:GetFont()
  -- if options.multiline then
  --   height = height * 3
  -- end
  -- editBox:SetSize(options.width, height)

  -- todo: still need this?
  -- addon:ApplyBackgroundStyle(editBox)

  local labelOpts = {
    text = options.label,
    anchor = "TOPLEFT",
  }
  local label = addon:CreateFrame("FormLabel", frameName.."Label", editBox, labelOpts)

  addon:ApplyFormFieldMethods(editBox, template)

  editBox._options = options
  editBox._label = label

  return editBox
end