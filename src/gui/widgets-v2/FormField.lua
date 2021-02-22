local _, addon = ...
local UIEvents = addon.UIEvents
local asserttype, assertf = addon.asserttype, addon.assertf

local methods = {
  ["GetFormValue"] = function(self)
    return self._formField.value
  end,
  ["SetFormValue"] = function(self, value, isUserInput)
    -- Value didn't change, take no action
    if self._formField.value == value then return end

    self._formField.value = value

    if isUserInput ~= false then
      self:SetDirty(true)
    end

    -- Notify the FormGroup whenever any of its fields' values' are changed
    -- Since a "FormField" is not a proper template, we cannot "FireCustomScriptEvent".
    -- We have to go around that process by calling UIEvents manually.
    UIEvents:Publish(self, "OnFormValueChange", value, isUserInput)
  end,
  ["ClearFormValue"] = function(self, isUserInput)
    self:SetFormValue(self, nil, isUserInput)
  end,

  ["IsDirty"] = function(self)
    return self._formField.isDirty
  end,
  ["SetDirty"] = function(self, flag)
    if flag == nil then flag = true end

    self._formField.isDirty = flag and true
  end,
  ["ClearDirty"] = function(self)
    self._formField.isDirty = false
  end,

  ["GetFormGroup"] = function(self)
    return self._formField.formGroup
  end,
  ["SetFormGroup"] = function(self, formGroup)
    asserttype(formGroup, "table", "formGroup", "SetFormGroup")
    assertf(not self._formField.formGroup, "SetFormGroup: %s is already part of FormGroup %s",
      self:GetName(), self._formField.formGroup:GetName())

    self._formField.formGroup = formGroup
  end,
  ["ClearFormGroup"] = function(self)
    self._formField.formGroup = nil
  end,
}

--- Applies FormField methods to the provided UI frame. A FormField is not a UI frame or widget,
--- only a set of methods that can be added to one.
--- @param frame table A UI frame to add FormField methods to.
--- @param template table (optional) The widget template to ensure that it registers the right custom events
function addon:ApplyFormFieldMethods(frame, template)
  asserttype(frame, "table", "frame", "ApplyFormFieldMethods")
  assertf(not frame._formField, "CreateFormField: %s is already a FormField", frame:GetName())

  if template then
    template:RegisterCustomScriptEvent("OnFormValueChange")
  end

  frame._formField = {
    value = nil,
    isDirty = false,
    formGroup = nil,
  }

  addon:ApplyMethods(frame, methods)
end