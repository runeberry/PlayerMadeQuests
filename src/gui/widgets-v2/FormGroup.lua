local _, addon = ...
local UIEvents = addon.UIEvents
local asserttype, assertf = addon.asserttype, addon.assertf
local logger = addon.Logger:NewLogger("Forms")

local template = addon:NewFrame("FormGroup")

template:RegisterCustomScriptEvent("OnFormStateChange")
template:RegisterCustomScriptEvent("OnSubmit")

local function addField(formGroup, fieldName, field)
  formGroup._fieldsByIndex[#formGroup._fieldsByIndex+1] = field
  formGroup._fieldsByName[fieldName] = field
end

local function getFieldsByIndex(formGroup)
  return formGroup._fieldsByIndex
end

local function getFieldsByName(formGroup)
  return formGroup._fieldsByName
end

local function getField(formGroup, fieldNameOrIndex)
  local field

  if type(fieldNameOrIndex) == "number" then
    field = formGroup._fieldsByIndex[fieldNameOrIndex]
  elseif type(fieldNameOrIndex) == "string" then
    field = formGroup._fieldsByName[fieldNameOrIndex]
  end

  return field
end

template:AddMethods({
  ["AddFormField"] = function(self, fieldName, formField)
    asserttype(formField, "table", "formField", "FormGroup:AddFormField")
    asserttype(fieldName, "string", "fieldName", "FormGroup:AddFormField")
    assertf(not self._fieldsByName[fieldName], "AddFormField: Field name %s is already in use on FormGroup %s", fieldName, self:GetName())
    assert(formField._formField, "AddFormField: The provided frame is not a FormField")

    addField(self, fieldName, formField)

    -- Since a "FormField" is not a proper template, we cannot "FireCustomScriptEvent".
    -- We have to go around that process by calling UIEvents manually.
    UIEvents:Subscribe(formField, "OnFormValueChange", function(_, value, isUserInput)
      -- todo: this is inefficient. Could we keep a separate state object updated instead?
      local state = self:GetCurrentFormState()
      self:FireCustomScriptEvent("OnFormStateChange", state)
    end)
  end,

  ["GetCurrentFormState"] = function(self)
    local state = {}

    for fieldName, field in pairs(getFieldsByName(self)) do
      state[fieldName] = field:GetFormValue()
    end

    return state
  end,
  ["GetSavedFormState"] = function(self, offsetOrName)
    assertf(type(offsetOrName) == "number" or type(offsetOrName) == "string",
      "GetSavedFormState: must provide a state name (string) or index offset (number)")

    if type(offsetOrName) == "string" then
      -- Return the state at a specific save state name
      return self._formStates[offsetOrName]
    else
      -- Go back X number of sequential states and return that
      -- For example, 0 returns the last saved state, 1 returns the state before that, etc.
      local index = #self._formStates - math.abs(offsetOrName) -- pos or neg work the same
      index = math.max(1, index) -- Cannot access an index less than 1
      return self._formStates[index]
    end
  end,
  ["LoadFormState"] = function(self, state)
    asserttype(state, "table", "state", "FormGroup:LoadFormState")

    for fieldName, stateValue in pairs(state) do
      local field = getField(self, fieldName)
      if field then
        field:SetFormValue(stateValue, false)
      end
    end

    logger:Trace("(%s) Loaded form state from table", self:GetName())
  end,
  ["LoadSavedFormState"] = function(self, offsetOrName)
    local state = self:GetSavedFormState(offsetOrName)

    for fieldName, stateValue in pairs(state) do
      local field = getField(self, fieldName)
      field:SetFormValue(stateValue, false)
    end

    logger:Trace("(%s) Loaded saved form state %s", self:GetName(), tostring(offsetOrName))
  end,
  ["SaveFormState"] = function(self, name)
    local state = self:GetCurrentFormState()
    local stateName

    if type(name) == "string" then
      -- Save the state with a specific name that can be recalled later
      self._formStates[name] = state
      stateName = name
    else
      -- Save the state as the next one in sequence
      self._formStates[#self._formStates+1] = state
      stateName = tostring(#self._formStates)
    end

    logger:Trace("(%s) Saved form states %s", self:GetName(), stateName)
  end,
  ["SubmitForm"] = function(self)
    local state = self:GetCurrentFormState()
    self:FireCustomScriptEvent("OnSubmit", state)
  end,

  ["IsFormDirty"] = function(self)
    for _, field in pairs(getFieldsByIndex(self)) do
      -- If any field is dirty, then the form is dirty
      if field:IsDirty() then return true end
    end

    return false
  end,
  ["ClearForm"] = function(self)
    for _, field in pairs(getFieldsByIndex(self)) do
      field:ClearFormValue(false)
    end

    self._formStates = {}

    logger:Trace("(%s) Cleared form", self:GetName())
  end,
})

template:AddScripts({
  ["OnFormStateChange"] = function(self, state)
    logger:Trace("(%s) State changed", self:GetName())
  end,
  ["OnSubmit"] = function(self, state)
    logger:Trace("(%s) Submitted form", self:GetName())
  end
})

--- Note that a FormGroup is not intended to be placed on screen like a standard UI Frame.
--- It's intended to be used as a "logical frame", with a set of behaviors to group other frames
--- (FormFields) together, without being placed on the screen itself.
function template:Create(formGroup, options)
  formGroup._fieldsByIndex = {}
  formGroup._fieldsByName = {}
  formGroup._formStates = {}
end