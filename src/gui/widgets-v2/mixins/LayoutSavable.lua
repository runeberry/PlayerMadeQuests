local _, addon = ...
local strjoin, strsplit, UIParent = addon.G.strjoin, addon.G.strsplit, addon.G.UIParent

local template = addon:NewMixin("LayoutSavable")

template:SetDefaultOptions({
  layoutAutoSave = true,      -- [boolean] Should this frame's layout be saved whenever it's changed?
  layoutAutoLoad = true,      -- [boolean] Should this frame's saved layout be set as soon as it's created?
  layoutSaveOpenState = true, -- [boolean] Should this frame's open/closed state also be saved?
  -- [string] ("p1|p2|x|y|w|h|shown") What should this frame's layout be if no layout is saved?
  layoutDefault = "CENTER|CENTER|0|0|400|400|true",
})

local configSectionName = "WidgetLayouts"
local separator = "|"

local function isChildOfUIParent(frame)
  return frame:GetParent() == UIParent
end

-- For some reason GetPoint() returns the wrong position unless you move the window
-- Still trying to figure this one out
local function isInaccuratePoint(p1, p2, x, y)
  return p1 == "CENTER" and p2 == "CENTER" and x == 0 and y == 0
end

local function getUIParentPoint(frame)
  local p1, relative, p2, x, y
  local i = 1
  -- Loop over points by index until we stop getting data back
  repeat
    p1, relative, p2, x, y = frame:GetPoint(i)
    if not p1 then return end
    if relative == nil or relative == UIParent and not isInaccuratePoint(p1, p2, x, y) then
      return p1, p2, x, y
    end
    i = i + 1
  until true
end

template:AddMethods({
  ["AutoSaveLayout"] = function(self)
    if self:GetOptions().autoSave then
      self:SaveLayout()
    end
  end,
  ["SaveLayout"] = function(self)
    -- Bypass Blizzard's layout cache so it doesn't interfere with this one
    self:SetUserPlaced(false)
    local frameName = self:GetName()

    if not isChildOfUIParent(self) then
      addon.UILogger:Debug("Unable to SaveLayout for %s: Frame is not a child of UIParent", frameName)
      return
    end

    local p1, p2, x, y = getUIParentPoint(self)
    if not p1 then
      addon.UILogger:Debug("Unable to SaveLayout for %s: Could not read a valid anchor point", frameName)
      return
    end

    local w, h = self:GetSize()
    local shown = tostring(self:IsShown())
    local serialized = strjoin(separator, p1, p2, x, y, w, h, shown)

    local layouts = addon.Config:GetValue(configSectionName)
    layouts[frameName] = serialized
    addon.Config:SaveValue(configSectionName, layouts)

    shown = (shown == "true" and "shown") or "hidden"
    addon.UILogger:Trace("SaveLayout: %s\n%s-%s (%i,%i) %ix%i [%s]", frameName, p1, p2, x, y, w, h, shown)
  end,
  ["LoadLayout"] = function(self)
    local frameName = self:GetName()
    local options = self:GetOptions()

    if not isChildOfUIParent(self) then
      addon.UILogger:Debug("Unable to LoadLayout for %s: Frame is not a child of UIParent", frameName)
      return
    end

    local layouts = addon.Config:GetValue(configSectionName)
    local serialized = layouts[frameName]
    local p1, p2, x, y, w, h, shown
    if serialized then
      p1, p2, x, y, w, h, shown = strsplit(separator, serialized)
    else
      -- No layout has been saved for this frame
      p1, p2, x, y, w, h, shown = strsplit(separator, options.layoutDefault)
    end

    x, y, w, h = tonumber(x), tonumber(y), tonumber(w), tonumber(h)
    shown = addon:ConvertValue(shown, "boolean")
    if not options.layoutSaveOpenState then
      shown = false
    end

    self:ClearAllPoints()
    self:SetPoint(p1, UIParent, p2, x, y)
    self:SetSize(w, h)
    self:SetShown(shown)

    shown = (shown and "shown") or "hidden"
    addon.UILogger:Trace("LoadLayout: %s\n%s-%s (%i,%i) %ix%i [%s]", frameName, p1, p2, x, y, w, h, shown)
  end,
  ["ResetLayout"] = function(self)
    local frameName = self:GetName()

    local layouts = addon.Config:GetValue(configSectionName)
    layouts[frameName] = nil
    addon.Config:SaveValue(configSectionName, layouts)

    self:LoadLayout()
  end
})

template:AddScripts({
  ["OnShow"] = function(self)
    self:AutoSaveLayout()
  end,
  ["OnHide"] = function(self)
    self:AutoSaveLayout()
  end,
})

function template:Create(frame, options)
  if options.autoLoad then
    frame:LoadLayout()
  end
end