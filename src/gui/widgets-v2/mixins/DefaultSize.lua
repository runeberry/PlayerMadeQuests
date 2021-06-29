local _, addon = ...

local template = addon:NewMixin("DefaultSize")

template:SetDefaultOptions({
  defaultSize = nil,    -- [XY or function(frame) => width, height]
  defaultWidth = nil,   -- [number or function(frame) => number]
  defaultHeight = nil,  -- [number or function(frame) => number]
})

template:AddScripts({
  ["AfterCreate"] = function(frame)
    local options = frame:GetOptions()

    local width, height, err
    if options.defaultSize then

      if type(options.defaultSize) == "function" then
        width, height = options.defaultSize(frame)
      elseif type(options.defaultSize) == "number" or type(options.defaultSize) == "table" then
        width, height = addon:UnpackXY(options.defaultSize)
      else
        err = "defaultSize must be a function or XY value"
      end
    elseif options.defaultWidth or options.defaultHeight then
      if type(options.defaultWidth) == "function" then
        width = options.defaultWidth(frame)
      elseif type(options.defaultWidth) == "number" then
        width = options.defaultWidth
      elseif options.defaultWidth then
        err = "defaultWidth must be a function or number"
      end

      if type(options.defaultHeight) == "function" then
        height = options.defaultHeight(frame)
      elseif type(options.defaultHeight) == "number" then
        height = options.defaultHeight
      elseif options.defaultHeight then
        err = "defaultHeight must be a function or number"
      end
    end

    if err then
      addon.UILogger:Error("Failed to set DefaultSize on %s: %s", frame:GetName() or "frame", err)
      return
    end
    print("Before", frame:GetName(), frame:GetWidth(), frame:GetHeight())
    if width then frame:SetWidth(width) end
    if height then frame:SetHeight(height) end
    print("After", frame:GetName(), frame:GetWidth(), frame:GetHeight())
  end,
})