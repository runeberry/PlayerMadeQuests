local _, addon = ...
local UIEvents = addon.UIEvents
local asserttype, assertf = addon.asserttype, addon.assertf

local template = addon:NewFrame("FormField")
template:AddMixin("FormLabel")
template:RegisterCustomScriptEvent("OnFormValueChange")

template:AddMethods({
  ["GetFormValue"] = function(self)
    return self._formField.value
  end,
  ["SetFormValue"] = function(self, value, isUserInput)
    -- Value didn't change, take no action
    if self._formField.value == value then return end

    self._formField.value = value

    if isUserInput == nil then isUserInput = true end
    if isUserInput then
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
})

function template:Create(frame)
  frame._formField = {
    value = nil,
    isDirty = false,
    formGroup = nil,
  }
end