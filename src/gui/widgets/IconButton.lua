local _, addon = ...
local CreateFrame = addon.G.CreateFrame

local widget = addon.CustomWidgets:NewWidget("IconButton")

local tooltip
local tooltipCancelToken
addon:OnGuiReady(function()
  tooltip = CreateFrame("GameTooltip", "PMQ_MenuIconTooltip", nil, "GameTooltipTemplate")
end)

local tileTextureName = "MenuIcons"
local numTilesX = 8
local numTilesY = 8
local tileWidthPx = 16
local tileHeightPx = 16

local methods = {
  ["SetIconTile"] = function(self, tileName)
    local tileInfo = addon.IconList[tileName]
    assert(tileInfo, tileName.." is not recognized icon tile name")

    local row, col = tileInfo[1], tileInfo[2]

    local left = (col - 1) / numTilesX
    local right = col / numTilesX
    local top = (row - 1) / numTilesY
    local bottom = row / numTilesY

    self._iconTexture:SetTexCoord(left, right, top, bottom)
  end,
  ["ShowTooltip"] = function(self)
    if not self._hasTooltip then return end

    if tooltipCancelToken then
      addon.Ace:CancelTimer(tooltipCancelToken)
    end

    tooltipCancelToken = addon.Ace:ScheduleTimer(function()
      tooltipCancelToken = nil
      tooltip:SetOwner(self, "ANCHOR_NONE")
      tooltip:SetPoint("BOTTOMLEFT", self, "TOPRIGHT")
      if self._options.tooltipText then
        tooltip:AddLine(self._options.tooltipText)
      end
      if self._options.tooltipDescription then
        tooltip:AddLine(self._options.tooltipDescription)
      end
      tooltip:Show()
    end, self._options.tooltipDelay)
  end,
  ["HideTooltip"] = function(self)
    if not self._hasTooltip then return end

    if tooltipCancelToken then
      addon.Ace:CancelTimer(tooltipCancelToken)
      tooltipCancelToken = nil
    end

    tooltip:Hide()
  end,
}

local scripts = {
  ["OnEnter"] = function(self)
    if self._options.highlightIcon then
      self:SetIconTile(self._options.highlightIcon)
    end
    self:ShowTooltip()
  end,
  ["OnLeave"] = function(self)
    if self._options.highlightIcon then
      self:SetIconTile(self._options.icon)
    end
    self:HideTooltip()
  end,
  ["OnEnable"] = function(self)
    if self._options.disabledIcon then
      self:SetIconTile(self._options.icon)
    end
  end,
  ["OnDisable"] = function(self)
    if self._options.disabledIcon then
      self:SetIconTile(self._options.disabledIcon)
    end
  end,
}

function widget:Create(parent, options)
  options = options or { template = "default" }

  while options.template do
    local template = addon.IconButtonTemplates[options.template]
    assert(template, options.template.." is not a valid icon button template")
    local nextTemplate = template.template
    options = addon:MergeTable(template, options)
    options.template = nextTemplate
  end

  assert(options.icon, "An icon tile name is required")

  local button = CreateFrame("Button", nil, parent)
  button._options = options
  button:SetSize(options.width, options.height)

  for fname, fn in pairs(methods) do
    button[fname] = fn
  end

  for fname, fn in pairs(scripts) do
    button:SetScript(fname, fn)
  end

  local tex = addon:CreateImageTexture(button, tileTextureName)
  button._iconTexture = tex
  button:SetIconTile(options.icon)
  tex:SetPoint(options.iconAnchor, button, options.iconAnchor)
  tex:SetSize(tileWidthPx, tileHeightPx)

  if options.tooltipText or options.tooltipDescription then
    button._hasTooltip = true
  end

  return button
end