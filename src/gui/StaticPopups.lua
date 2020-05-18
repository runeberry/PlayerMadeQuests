local _, addon = ...
local StaticPopupDialogs, StaticPopup_Show, StaticPopup_Hide =
  addon.G.StaticPopupDialogs, addon.G.StaticPopup_Show, addon.G.StaticPopup_Hide

addon.StaticPopups = {}

local function popup_SetText(self, text)
  if type(text) == "string" then
    self.text = text
  elseif type(text) == "function" then
    -- This should return a string and will be called on show
    self._textFunction = text
  end
end

local function popup_SetYesButton(self, text, fn)
  self.button1 = text
  if fn then
    self.OnAccept = function()
      addon:catch(fn)
    end
  end
end

local function popup_SetNoButton(self, text)
  self.button2 = text
end

local function popup_SetOtherButton(self, text, fn)
  self.button3 = text
  if fn then
    self.OnAlt = function()
      addon:catch(fn)
    end
  end
end

local function popup_Show(self)
  if self._textFunction then
    self.text = self._textFunction()
  end
  StaticPopup_Show(self._globalId)
end

local function popup_Hide(self)
  StaticPopup_Hide(self._globalId)
end

function addon.StaticPopups:NewPopup(id)
  local globalId = "PMQ_"..id
  if StaticPopupDialogs[globalId] then
    addon.Logger:Error("Popup already exists with id:", id)
    return
  end

  local popup = {
    _id = id,
    _globalId = globalId,

    timeout = 0,

    SetText = popup_SetText,
    SetYesButton = popup_SetYesButton,
    SetNoButton = popup_SetNoButton,
    SetOtherButton = popup_SetOtherButton,

    Show = popup_Show,
    Hide = popup_Hide
  }

  StaticPopupDialogs["PMQ_"..id] = popup
  addon.Logger:Trace("Registered static popup:", id)
  return popup
end

function addon.StaticPopups:ShowPopup(id)
  local popup = StaticPopupDialogs["PMQ_"..id]
  if not popup then
    addon.Logger:Error("No popup exists with id:", id)
    return
  end
  popup:Show()
end

function addon.StaticPopups:HidePopup(id)
  local popup = StaticPopupDialogs["PMQ_"..id]
  if not popup then
    return
  end
  popup:Hide()
end