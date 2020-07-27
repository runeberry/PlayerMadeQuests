local _, addon = ...
local StaticPopupDialogs, StaticPopup_Show, StaticPopup_Hide =
  addon.G.StaticPopupDialogs, addon.G.StaticPopup_Show, addon.G.StaticPopup_Hide
local unpack = addon.G.unpack

addon.StaticPopups = {}

--[[
  Properties reserved for the popup by WoW:
  {
    text = "string",
    button1 = "string",   -- Yes
    button2 = "string",   -- No
    button3 = "string",   -- Maybe
    OnAccept = function,  -- I don't know
    OnAlt = function,     -- Can you repeat the question?
  }

  Properties added to the global popup by PMQ:
  {
    _globalId = "string", -- and all other _ properties
    Show = function,
    Hide = function,
    OnYes = function,
    OnOther = function,
  }

  Popup template properties:
  {
    message: "string" or function,
    yesText: "string",
    noText: "string",
    otherText: "string",
    yesHandler = function,
    otherHandler = function,
  }
--]]

local popupMethods = {
  ["Show"] = function(self, ...)
    if self._messageFunction then
      self.text = string.format(self._messageFunction(...))
    end
    self._varargs = { ... }
    StaticPopup_Show(self._globalId)
  end,
  ["Hide"] = function(self)
    self._varargs = nil
    StaticPopup_Hide(self._globalId)
  end,
  ["OnYes"] = function(self, fn)
    self._onYes = fn
    return self
  end,
  ["OnOther"] = function(self, fn)
    self._onOther = fn
    return self
  end
}

local function buildPopup(template, globalId)
  local popup = {
    _globalId = globalId
  }

  if type(template.message) == "string" then
    popup.text = template.message
  elseif type(template.message) == "function" then
    popup._messageFunction = template.message
  end

  popup.button1 = template.yesText
  popup.button2 = template.noText
  popup.button3 = template.otherText

  if template.yesHandler then
    popup._yesHandler = template.yesHandler
    popup.OnAccept = function()
      addon:catch(function()
        local v = popup._varargs or {}
        popup._yesHandler(unpack(v))
        if popup._onYes then
          popup._onYes()
        end
      end)
      popup._onYes = nil
    end
  end
  if template.otherHandler then
    popup._otherHandler = template.otherHandler
    popup.OnAlt = function()
      addon:catch(function()
        local v = popup._varargs or {}
        popup._otherHandler(unpack(v))
        if popup._onOther then
          popup._onOther()
        end
      end)
      popup._onOther = nil
    end
  end

  for name, method in pairs(popupMethods) do
    popup[name] = method
  end

  return popup
end

local function getGlobalPopup(name)
  local globalId = "PMQ_"..name

  local existing = StaticPopupDialogs[globalId]
  if existing then return existing end

  local template = addon.StaticPopupsList[name]
  if not template then
    addon.UILogger:Error("No popup template exists with name: %s", name)
    return
  end

  local popup = buildPopup(template, globalId)
  StaticPopupDialogs[globalId] = popup
  addon.UILogger:Trace("Registered static popup: %s", name)

  return popup
end

function addon.StaticPopups:Show(name, ...)
  local popup = getGlobalPopup(name)
  if not popup then return end
  addon:catch(popup.Show, popup, ...)
  return popup
end

function addon.StaticPopups:Hide(name)
  local popup = getGlobalPopup(name)
  if not popup then return end
  addon:catch(popup.Hide, popup)
  return popup
end