local _, addon = ...
addon:traceFile("CustomWidgets.lua")

addon.CustomWidgets = {}
local widgets = {}

function addon.CustomWidgets:NewWidget(name)
  if name == nil or name == "" then
    addon:error("Unable to create CustomWidget: name is required")
    return {}
  end
  if widgets[name] then
    addon:warn("Unable to create CustomWidget: widget already exists with name '"..name.."'")
    return {}
  end

  local widgetTemplate = {}
  widgets[name] = widgetTemplate
  return widgetTemplate
end

function addon.CustomWidgets:CreateWidget(name, ...)
  local errPrefix = "Failed to create widget '"..name.."': "
  local widgetTemplate = widgets[name]
  if widgetTemplate == nil then
    error(errPrefix.."No custom widget is registered with this name")
  end
  if type(widgetTemplate.Create) ~= "function" then
    error(errPrefix.."Widget does not have a Create function")
  end
  local widget = widgetTemplate.Create(...)
  if widget == nil then
    error(errPrefix.."Widget constructor returned nil")
  end
  return widget
end