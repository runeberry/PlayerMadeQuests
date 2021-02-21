local _, addon = ...
local asserttype = addon.asserttype

--- The UIEvents broker differs from other brokers in that a UI Frame must
--- be passed as the first arg to Publish and Subscribe, followed by the ScriptType
--- (like "OnSubmit"), then handler or publish args.
addon.UIEvents = addon.Events:CreateBroker("UIEvent")

local internalPublish, internalSubscribe

--- The UIEvent name is a combination of the frame's name and the scriptType involved.
--- For example: "PMQ_FancyButtonR1C1:OnClick"
local function getUIEventName(frame, scriptType)
  asserttype(frame, "table", "frame")
  asserttype(scriptType, "string", "scriptType")

  local frameName = frame.GetName and frame:GetName()
  if not frameName then
    frameName = tostring(frame)
  end

  return string.format("%s:%s", frameName, scriptType)
end

local methodOverrides = {
  ["Publish"] = function(self, frame, scriptType, ...)
    local eventName = getUIEventName(frame, scriptType)
    internalPublish(addon.UIEvents, eventName, ...)
  end,
  ["Subscribe"] = function(self, frame, scriptType, handler)
    local eventName = getUIEventName(frame, scriptType)
    internalSubscribe(addon.UIEvents, eventName, handler)
  end,
}

addon:OnBackendStart(function()
  internalPublish = addon.UIEvents.Publish
  internalSubscribe = addon.UIEvents.Subscribe

  addon:ApplyMethods(addon.UIEvents, methodOverrides, true)
end)