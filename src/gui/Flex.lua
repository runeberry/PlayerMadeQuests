local _, addon = ...
local flexLogger = addon.Logger:NewLogger("Flex")

--[[
  CalculateFlex accepts the following type:
  { -- an array of...
    {
      size = 0,         -- [number] absolute size in px, top priority
      min = 0,          -- [number] minimum size in px
      max = 0,          -- [number] maximum size in px
      flex = 0,         -- [number] # flex units to use

      -- Internal properties
      _flexRatio = 0,   -- [number] flex / flexSum
    }
  }

  And returns an array of px widths, like this...
  { 15, 30, 30, 22 }
  ...where ret[i] == the calculated px width of column i.
--]]

-- Enable this flag if troubleshooting flex sizing
local flexLogEnabled = false

local function flexLog(...)
  if not flexLogEnabled then return end
  flexLogger:Trace(...)
end

local function isBetween(val, min, max)
  min = min or 1
  max = max or 999999

  if val < min then
    return false, min
  elseif val > max then
    return false, max
  end

  return true, val
end

local function getBetween(val, min, max)
  local ok, val2 = isBetween(val, min, max)
  return val2
end

local function calcFlexRatios(flexParams, flexResults)
  local flexSum = 0
  for i, fp in ipairs(flexParams) do
    if flexResults[i] then
      -- Col has already been sized, does not contribute to flex width
    elseif fp.size then
      -- Col is absolutely sized, does not contributed to flex width
    elseif fp.flex then
      -- Flex size is explicitly defined
      flexSum = flexSum + fp.flex
    else
      -- Flex size is not defined, implicitly 1 unit
      fp.flex = 1
      flexSum = flexSum + fp.flex
    end
  end

  -- No flex containers to size, everything is already sized
  if flexSum == 0 then return end

  for _, fp in ipairs(flexParams) do
    if fp.flex then
      fp._flexRatio = fp.flex / flexSum
    end
  end
end

local function calcFlexInternal(flexParams, flexSpace, flexResults)
  local preWidths = {}
  flexLog("Available flex space: %.2f", flexSpace)

  -- Ratios change based on how many columns are being considered for flex
  calcFlexRatios(flexParams, flexResults)

  for i, fp in ipairs(flexParams) do
    if not flexResults[i] then
      local recalc, width

      if fp.size then
        width = getBetween(fp.size, fp.min, fp.max)
        recalc = true -- Always recalc when an absolute width is assigned
      elseif fp._flexRatio then
        -- Width is a portion of the total available flex space
        local flexWidth = fp._flexRatio * flexSpace
        recalc, width = isBetween(flexWidth, fp.min, fp.max)
        recalc = not recalc -- actually want to recalc if isBetween returns false
      end
      flexLog("Col #%i: %s < %.2f < %s", i, tostring(fp.min), width, tostring(fp.max))

      if recalc then
        -- This col's width had to be assigned outside of the standard flex algorithm because:
        -- * it was outside its min-max range, or
        -- * it was assigned an absolute (non-flex) width
        -- Rerun the calcs with this width already assigned (will be excluded from recalc)
        flexResults[i] = width
        flexLog("Col #%i: assigned absolute width %.2f, recalculating...", i, width)
        calcFlexInternal(flexParams, flexSpace - width, flexResults)
      else
        -- Don't assign width directly yet, in case we need to recalc based a min-max resize
        preWidths[i] = width
      end
    end
  end

  for i, fp in ipairs(flexParams) do
    -- For any cols that have not been given width
    -- (should happen at the innermost recursion of this fn)
    if not flexResults[i] then
      if preWidths[i] then
        flexLog("Col #%i: assigned flex width %.2f", i, preWidths[i])
        flexResults[i] = preWidths[i]
      else
        flexLog("Failed to calculate flex width for column #%i", i)
        flexResults[i] = 1
      end
    end
  end
end

--- Calculates the flex widths for an array of width information
--- @param flexParams table an array of flex width objects
--- @param flexSpace number the number of px available for distributing flex widths
--- @return table table an array of numbers representing absolute sizes
function addon:CalculateFlex(flexParams, flexSpace)
  if not flexParams or #flexParams == 0 then return {} end

  local flexResults = {}
  calcFlexInternal(flexParams, flexSpace, flexResults)

  return flexResults
end