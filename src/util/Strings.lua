local _, addon = ...

local colors = {
  red = "ffff0000",
  green = "ff1eff00",
  blue = "ff0070dd",
  grey = "ff9d9d9d",
  white = "ffffffff",
  black = "ff000000",
  purple = "ffa335ee",
  orange = "ffff8000",
  yellow = "ffffff00"
}

-- Use the mapped color if available, otherwise assume the string is an 8-char hex string
-- If no color is specified, default to white
function addon:GetEscapeColor(color)
  return "|c"..(colors[color] or color or colors.white)
end

function addon:Colorize(color, str)
  return addon:GetEscapeColor(color)..str.."|r"
end

function addon:Pluralize(num, singular, plural)
  if num == 1 then
    return singular
  else
    -- If no plural is provided, you get lazy pluralization
    return plural or singular.."s"
  end
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