local _, addon = ...

addon.CustomWidgets = {}
local widgets = {}

local function wrapScriptSet(event)
  return function(self, fn)
    local eventScripts = self._scripts[event]
    if not eventScripts then
      eventScripts = {}
      self._scripts[event] = eventScripts
    end
    table.insert(eventScripts, fn)
  end
end

local function wrapScriptRun(fn, event)
  return function(self, ...)
    fn(self, ...)

    if self._parent._scripts[event] then
      for _, f in pairs(self._parent._scripts[event]) do
        f(self._parent, ...)
      end
    end
  end
end

function addon.CustomWidgets:NewWidget(name)
  if name == nil or name == "" then
    addon.UILogger:Error("Unable to create CustomWidget: name is required")
    return {}
  end
  if widgets[name] then
    addon.UILogger:Warn("Unable to create CustomWidget: widget already exists with name '"..name.."'")
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
  local widget = widgetTemplate:Create(...)
  if widget == nil then
    error(errPrefix.."Widget constructor returned nil")
  end
  return widget
end

-- Example:
-- this does - scriptFrame:SetScript("OnEnterPressed")
-- later, you can customize with: widgetFrame:OnEnterPressed(fn)
--   and it will run you wf function AFTER the sf function from the methodTable
function addon.CustomWidgets:ApplyScripts(widgetFrame, scriptFrame, methodTable)
  scriptFrame._parent = widgetFrame
  widgetFrame._scripts = {}

  for event, fn in pairs(methodTable) do
    scriptFrame:SetScript(event, wrapScriptRun(fn, event))
    widgetFrame[event] = wrapScriptSet(event)
  end
end