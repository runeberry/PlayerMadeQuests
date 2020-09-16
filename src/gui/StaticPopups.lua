local _, addon = ...
local StaticPopupDialogs, StaticPopup_Show, StaticPopup_Hide =
  addon.G.StaticPopupDialogs, addon.G.StaticPopup_Show, addon.G.StaticPopup_Hide
local unpack = addon.G.unpack

addon.StaticPopups = {}

local popupsEnabled
addon:OnGuiStart(function()
  popupsEnabled = addon.Config:GetValue("ENABLE_GUI")
end)

--[[
  Properties reserved for the popup by WoW:
  {
    text = "string",
    button1 = "string",   -- Yes
    button2 = "string",   -- No
    button3 = "string",   -- Maybe
    OnAccept = function,  -- I don't know
    OnAlt = function,     -- Can you repeat the question?
    OnShow = function,
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
    editBox: "string" or function, -- show an editbox, defaulting to this message
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

  if template.editBox then
    popup.hasEditBox = true
    popup.OnShow = function(self)
      addon:catch(function()
        if type(template.editBox) == "string" then
          self.editBox:SetText(template.editBox)
        elseif type(template.editBox) == "function" then
          local v = popup._varargs or {}
          local text, doHighlight = template.editBox(unpack(v))
          self.editBox:SetText(text)
          if doHighlight then
            self.editBox:HighlightText()
            self.editBox:SetCursorPosition(0)
          end
        end
      end)
    end
    popup.OnHide = function(self)
      addon:catch(function()
        self.editBox:SetText("")
      end)
    end
  end

  -- todo: the OnYes handler can only be triggered if the SP's yesHandler is not nil
  -- Ideally this should work whether or not you have a yesHandler on the SP
  if template.yesHandler then
    popup._yesHandler = template.yesHandler
    popup.OnAccept = function(self)
      addon:catch(function()
        local v = popup._varargs or {}
        local text
        if self.editBox then
          text = self.editBox:GetText()
        end
        local args = { unpack(v) }
        args[#args+1] = text
        popup._yesHandler(unpack(args))
        if popup._onYes then
          popup._onYes()
        end
      end)
      popup._onYes = nil
    end
  end
  if template.otherHandler then
    popup._otherHandler = template.otherHandler
    popup.OnAlt = function(self)
      addon:catch(function()
        local v = popup._varargs or {}
        local text
        if self.editBox then
          text = self.editBox:GetText()
        end
        popup._otherHandler(unpack(v), text)
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
  if not popupsEnabled then return end
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