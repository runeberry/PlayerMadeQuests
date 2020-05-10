local _, addon = ...

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

  local widget = {}
  widgets[name] = {}
  return widget
end

function addon.CustomWidgets:CreateWidget(name, ...)
  local constructor = widgets[name]
  if constructor == nil then
    error("No custom widget exists with name: "..name)
  end
  local ok, widget = addon:catch(constructor, ...)
  if not ok then
    return nil
  elseif widget == nil then
    addon:error("Failed to build custom widget: constructor returned nil for widget '"..name.."'")
    return nil
  end
  return widget
end