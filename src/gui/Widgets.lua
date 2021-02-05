local _, addon = ...
local assertf, asserttype = addon.assertf, addon.asserttype

local widgetTemplates = {} -- Widget creation instructions, indexed by widgetType
local widgets = {} -- Instances of created widgets, indexed by frameName

local templateMethods = {
  ["Create"] = function()
    -- All templates should override this method
    error("Widget template must implement method: Create")
  end
}

local function assertIsFrame(frame)
  asserttype(frame, "table", "frame", "assertIsFrame", 2)
  if type(frame.RegisterEvent) ~= "function" then
    error("assertIsFrame: frame does not appear to be a UI Frame", 2)
  end
end

function addon:NewWidget(widgetType)
  local widgetTemplate = {}
  addon:ApplyMethods(widgetTemplate, templateMethods)

  -- Always return the template even if validation fails, so we don't get null refs during file load
  if type(widgetType) ~= "string" then
    addon.UILogger:Error("Failed to create NewWidget: widgetType is required")
    return widgetTemplate
  end
  if widgetTemplates[widgetType] then
    addon.UILogger:Error("Failed to create NewWidget: widgetType \"%s\" already exists", widgetType)
    return widgetTemplate
  end

  -- But only register the widget if validation was successful
  widgetTemplates[widgetType] = widgetTemplate
  return widgetTemplate
end

function addon:CreateWidget(widgetType, frameName, parent, ...)
  asserttype(widgetType, "string", "widgetType", "CreateWidget")
  asserttype(frameName or "", "string", "frameName", "CreateWidget")
  assertIsFrame(parent)

  local template = widgetTemplates[widgetType]
  assertf(template, "CreateWidget: %s is not a recognized widgetType", widgetType)

  -- Generate a unique global name for this frame
  frameName = frameName or widgetType.."_%i"
  frameName = addon:CreateGlobalName(frameName)
  assertf(not widgets[frameName], "CreateWidget: the frame name \"%s\" is already in use", frameName)

  local frame = template:Create(frameName, parent, ...)
  assertIsFrame(frame)

  widgets[frameName] = true
  return frame
end

function addon:ApplyScripts(frame, scripts)
  assertIsFrame(frame)

  for eventName, handler in pairs(scripts) do
    frame:SetScript(eventName, handler)
  end
end