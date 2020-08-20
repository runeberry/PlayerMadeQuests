local _, addon = ...
local strsplit = addon.G.strsplit

addon.ESCAPE_START = "|c"
addon.ESCAPE_END = "|r"

local colors = {
  red = "ffff0000",
  green = "ff1eff00",
  blue = "ff0070dd",
  grey = "ff9d9d9d",
  white = "ffffffff",
  black = "ff000000",
  purple = "ffa335ee",
  orange = "ffff8000",
  yellow = "ffffff00",
}

-- Just for fun, this will color logs for unit tests
if addon.USE_ANSI_COLORS then
  addon.ESCAPE_START = "\27["
  addon.ESCAPE_END = "\27[0m"
  colors = {
    red = "0;31m",
    green = "0;32m",
    blue = "0;34m",
    grey = "1;30m",
    white = "0m",
    black = "0;30m",
    purple = "0;35m",
    orange = "0;33m",
    yellow = "1;33m",
  }
end

--- Use the mapped color if available.
--- If no valid color is specified, default to white
function addon:GetEscapeColor(color)
  return colors[color] or colors.white
end

function addon:Colorize(color, str)
  return addon.ESCAPE_START..addon:GetEscapeColor(color)..str..addon.ESCAPE_END
end

function addon:Pluralize(num, singular, plural)
  if num == 1 then
    return singular
  else
    -- If no plural is provided, you get lazy pluralization
    return plural or singular.."s"
  end
end

function addon:GetVersionText()
  local major, minor, patch = addon.VERSION / 10000, (addon.VERSION / 100) % 100, addon.VERSION % 100
  local text = string.format("v%i.%i.%i", major, minor, patch)
  if addon.BRANCH then
    text = text.."-"..addon.BRANCH
  end
  return text
end

function addon:Enquote(str, quotes)
  str = tostring(str) or ""
  quotes = quotes or "\""

  if #quotes == 1 then
    return quotes..str..quotes
  else
    local first = quotes:sub(1, 1)
    local last = quotes:sub(2)
    return first..str..last
  end

  return str
end

-- Modifies each substring with the provided function
-- and inserts it back into the original string
-- Additional parameters can be passed to the function through varargs
-- Returns the modified string
function addon:strmod(str, findPattern, fn, ...)
  assert(type(str) == "string")
  assert(type(findPattern) == "string")
  assert(type(fn) == "function")

  -- To start, find the first occurence of the pattern within the string
  local from, to = 1
  local before, middle, after

  while true do
    from, to = str:find(findPattern, from)
    if not from then break end

    -- Each time the pattern is matched, extract that match from the string as a whole
    before = str:sub(1, from - 1)
    middle = str:sub(from, to)
    after = str:sub(to + 1, #str)
    -- print(before.."|"..middle.."|"..after)

    middle = fn(middle, ...)
    if middle == nil then
      middle = ""
    else
      middle = tostring(middle)
    end
    -- print(before.."|"..middle.."|"..after)

    -- Merge the modfiied string with its non-matching brethren
    str = before..middle..after

    -- Start the next search from the end of the previous search
    -- In case the modified string changed in size, adjust the pointer by the difference
    from = #before + #middle + 1
  end
  return str
end

local Q_start_ptn, Q_end_ptn = [=[^(['"])]=], [=[(['"])$]=]
local SQ_start_ptn, DQ_start_ptn, SQ_end_ptn, DQ_end_ptn = [[^(')]], [[^(")]], [[(')$]], [[(")$]]
local escSQ_end_ptn, escDQ_end_ptn = [[(\)(')]], [[(\)(")]]
local esc_ptn = [=[(\*)['"]$]=]

-- Splits a string into words, keeping quoted phrases intact
function addon:SplitWords(line)
  -- Solution adapted from: https://stackoverflow.com/a/28664691
  local words, buf, quoted = {}
  for str in line:gmatch("%S+") do
    local SQ_start = str:match(SQ_start_ptn)
    local SQ_end = str:match(SQ_end_ptn)
    local DQ_start = str:match(DQ_start_ptn)
    local DQ_end = str:match(DQ_end_ptn)
    local escSQ_end = str:match(escSQ_end_ptn)
    local escDQ_end = str:match(escDQ_end_ptn)
    local escaped = str:match(esc_ptn)
    if not quoted and SQ_start and (not SQ_end or escSQ_end) then
      buf, quoted = str, SQ_start
    elseif not quoted and DQ_start and (not DQ_end or escDQ_end) then
      buf, quoted = str, DQ_start
    elseif buf and (SQ_end == quoted or DQ_end == quoted) and #escaped % 2 == 0 then
      str, buf, quoted = buf .. ' ' .. str, nil, nil
    elseif buf then
      buf = buf .. ' ' .. str
    end
    if not buf then
      -- Remove outer quotes and unescape escaped quotes
      str = str:gsub(Q_start_ptn,""):gsub(Q_end_ptn,""):gsub([=[(\)(["'])]=], "%2")
      table.insert(words, str)
    end
  end
  if buf then error("Missing matching quote for: "..buf) end

  return words
end

local num_ptn = "%s-%d-%.?%d-%s-"
local two_ptn = "^"..num_ptn..","..num_ptn.."$"
local three_ptn = "^"..num_ptn..","..num_ptn..","..num_ptn.."$"

-- Splits a string of format "0.0,0.0,0.0" into coordinates x, y, and (optionally) radius
function addon:ParseCoords(str)
  assert(str and type(str) == "string", "Failed to ParseCoords: argument type "..type(str).." is not a string")
  assert(str:match(two_ptn) or str:match(three_ptn), "Failed to ParseCoords: coordinate string \""..str.."\" must be in format \"#,#,#\"")

  local x, y, radius = strsplit(",", str)
  x = tonumber(x)
  y = tonumber(y)
  if radius then radius = tonumber(radius) end
  return x, y, radius
end

-- Returns two coordinate values as: "(x, y)"
-- If a radius is included, returns as: "(x, y) +/- r"
local function trimDec(num) return string.format("%.2f", num):gsub("%.?0+$", "") end
function addon:PrettyCoords(x, y, radius)
  local coords = string.format("(%s, %s)", trimDec(x), trimDec(y))
  if radius then
    coords = coords.." +/- "..trimDec(radius)
  end
  return coords
end
