local _, addon = ...
local CreateFrame = addon.G.CreateFrame
local UIParent, UISpecialFrames = addon.G.UIParent, addon.G.UISpecialFrames
local strsplit, strjoin = addon.G.strsplit, addon.G.strjoin
local unpack = addon.G.unpack

local widget = addon.CustomWidgets:NewWidget("PopoutFrame")

-- For some reason GetPoint() returns the wrong position unless you move the window
-- Still trying to figure this one out
local function isInaccuratePoint(p1, p2, x, y)
  return p1 == "CENTER" and p2 == "CENTER" and x == 0 and y == 0
end

local styles = {
  ["default"] = {
    constructor = function(name)
      return CreateFrame("Frame", name, UIParent)
    end,
    getMover = function(frame)
      return frame
    end,
  },
  ["titlebar"] = {
    constructor = function(name, options)
      local frame = CreateFrame("Frame", name, UIParent)
      local title = addon.CustomWidgets:CreateWidget("TitleBar", frame, options)
      frame._title = title
      return frame
    end,
    getMover = function(frame)
      return frame._title
    end,
  },
}

local methods = {
  ["ToggleShown"] = function(self, flag)
    flag = flag or not self:IsShown()
    if flag then
      self:Show()
    else
      self:Hide()
    end
    self:SaveWindowState()
  end,
  ["SetWindowState"] = function(self, pos)
    self:ClearAllPoints()
    self:SetPoint(pos.p1, UIParent, pos.p2, pos.x, pos.y)
    self:SetSize(pos.w, pos.h)

    if pos.shown then
      self:Show()
    else
      self:Hide()
    end

    addon.UILogger:Trace("Set %s state: %s %s (%.2f, %.2f) %ix%i (%s)", self:GetName(), pos.p1, pos.p2, pos.x, pos.y, pos.w, pos.h, pos.shown)
  end,
  ["SaveWindowState"] = function(self)
    local p1, _, p2, x, y = self:GetPoint()
    local pos = self._options.position
    if isInaccuratePoint(p1, p2, x, y) and pos then
      addon.UILogger:Debug("Inaccurate point detected, adjusting frame")
      p1 = pos.p1
      p2 = pos.p2
      x = pos.x
      y = pos.y
    end

    local w, h = self:GetSize()
    local shown = tostring(self:IsVisible() or false)

    if not addon.PlayerSettings.FrameData then
      addon.PlayerSettings.FrameData = {}
    end

    addon.PlayerSettings.FrameData[self._name] = strjoin(",", p1, p2, x, y, w, h, shown)
    addon.SaveData:Save("Settings", addon.PlayerSettings)
    addon.UILogger:Trace("Saved %s state: %s %s (%.2f, %.2f) %ix%i (%s)", self:GetName(), p1, p2, x, y, w, h, shown)
  end,
  ["LoadWindowState"] = function(self)
    local frameData = addon.PlayerSettings.FrameData
    if not frameData or not frameData[self._name] then return end

    local p1, p2, x, y, w, h, shown = strsplit(",", frameData[self._name])
    local pos = {
      p1 = p1,
      p2 = p2,
      x = x,
      y = y,
      w = w,
      h = h,
    }

    if self._options.saveOpenState then
      -- Only used the saved 'shown' state if explicitly declared
      pos.shown = addon:ConvertValue(shown, "boolean") or false
    elseif self._options.position then
      -- Otherwise fall back on the frame's default shown state
      pos.shown = self._options.position.shown
    else
      -- If no default shown state is available, then hide the frame
      pos.shown = false
    end

    self:SetWindowState(pos)
  end,
}

function widget:Create(frameName, options)
  assert(type(frameName) == "string", "Failed to create PopoutFrame: name is required")

  frameName = "PMQ_"..frameName -- Add prefix to avoid global collisions
  options = options or {}

  local style = options.style or "default"
  assert(styles[style], "Failed to create PopoutFrame: style "..style.." is not recognized")
  local frame = styles[style].constructor(frameName, options.styleOptions)
  frame._name = frameName
  frame._options = options

  for methodName, fn in pairs(methods) do
    frame[methodName] = function(...)
      local args = { ... }
      addon:catch(function() fn(unpack(args)) end)
    end
  end

  if options.movable then
    frame:SetMovable(true)
    frame:EnableMouse(true)

    -- Get the specific component to register drag handlers
    local moveFrame = styles[style].getMover(frame)
    moveFrame:RegisterForDrag("LeftButton")
    moveFrame:SetScript("OnDragStart", function(self)
      frame:StartMoving()
    end)
    moveFrame:SetScript("OnDragStop", function(self)
      frame:StopMovingOrSizing()
      frame:SaveWindowState()
    end)
  end

  if options.resizable then
    addon.CustomWidgets:CreateWidget("Sizer", frame)
    frame:OnResize(function()
      frame:SaveWindowState()
    end)
    if type(options.resizable) == "table" then
      if options.resizable.minWidth and options.resizable.minHeight then
        frame:SetMinResize(options.resizable.minWidth, options.resizable.minHeight)
      end
    end
  end

  if options.escapable then
    -- Make closable with ESC
    table.insert(UISpecialFrames, frameName)
  end

  if options.position then
    frame:SetWindowState(options.position)
  end

  addon:OnSaveDataLoaded(function()
    frame:LoadWindowState()
  end)

  return frame
end