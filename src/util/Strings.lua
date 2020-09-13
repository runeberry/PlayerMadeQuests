local _, addon = ...
local strsplit = addon.G.strsplit

addon.Strings = {}

local charsets = {
  --- For use in-game
  WOW = {
    ESCAPE_START = "|c",
    ESCAPE_END = "|r",
    colors = {
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
  },
  -- For use in terminals outside of game
  ANSI = {
    ESCAPE_START = "\27[",
    ESCAPE_END = "\27[0m",
    colors = {
      red = "0;31m",
      green = "0;32m",
      blue = "0;34m",
      grey = "1;30m",
      white = "0;37m",
      black = "0;30m",
      purple = "0;35m",
      orange = "0;33m",
      yellow = "1;33m",
    }
  },
  -- Disables all special coloring
  NONE = {
    ESCAPE_START = "",
    ESCAPE_END = "",
    colors = {}
  }
}
local charset = charsets.NONE

function addon:Colorize(color, str)
  str = str or ""
  local c = charset.colors[color] or charset.colors.white or ""
  return charset.ESCAPE_START..c..str..charset.ESCAPE_END
end

function addon:SetCharset(name)
  assert(charsets[name], name.." is not a valid charset")
  charset = charsets[name]
end

function addon:Pluralize(num, singular, plural)
  if num == 1 then
    return singular
  else
    -- If no plural is provided, you get lazy pluralization
    return plural or singular.."s"
  end
end

function addon:GetVersionText(version, branch)
  version = version or addon.VERSION
  branch = branch or addon.BRANCH

  local major, minor, patch = version / 10000, (version / 100) % 100, version % 100
  local text = string.format("v%i.%i.%i", major, minor, patch)
  if branch then
    text = text.."-"..branch
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
  local coords = string.format("(%s, %s)", trimDec(x or 0), trimDec(y or 0))
  if radius then
    coords = coords.." +/- "..trimDec(radius)
  end
  return coords
end

-- Long text to use for display testing
addon.LOREM_IPSUM = [[Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Elementum curabitur vitae nunc sed. Purus ut faucibus pulvinar elementum integer enim neque volutpat. Venenatis tellus in metus vulputate. Porta non pulvinar neque laoreet suspendisse interdum. Nulla aliquet porttitor lacus luctus accumsan tortor posuere. Consequat nisl vel pretium lectus quam id leo. Egestas purus viverra accumsan in nisl nisi scelerisque eu ultrices. Odio aenean sed adipiscing diam. Viverra orci sagittis eu volutpat odio facilisis mauris.

In vitae turpis massa sed elementum tempus egestas sed. Gravida dictum fusce ut placerat. Sit amet mauris commodo quis. Mi proin sed libero enim sed faucibus turpis in eu. Ac turpis egestas integer eget aliquet. Suspendisse interdum consectetur libero id faucibus nisl tincidunt eget nullam. Sollicitudin aliquam ultrices sagittis orci a. Libero enim sed faucibus turpis in eu mi bibendum neque. Pharetra sit amet aliquam id diam maecenas ultricies mi eget. Ut diam quam nulla porttitor massa id. Ipsum consequat nisl vel pretium lectus quam id. Metus vulputate eu scelerisque felis imperdiet proin fermentum leo vel. Volutpat diam ut venenatis tellus. Dui ut ornare lectus sit. Adipiscing at in tellus integer feugiat scelerisque.

Ipsum consequat nisl vel pretium lectus quam id leo in. Porta non pulvinar neque laoreet suspendisse interdum consectetur libero. Congue nisi vitae suscipit tellus mauris. Sit amet cursus sit amet dictum. Neque aliquam vestibulum morbi blandit cursus risus at ultrices. Lectus arcu bibendum at varius vel pharetra vel turpis nunc. Velit aliquet sagittis id consectetur purus ut. Elementum sagittis vitae et leo duis ut diam. Dictumst quisque sagittis purus sit amet volutpat consequat mauris. Ut tellus elementum sagittis vitae et. At tellus at urna condimentum mattis pellentesque. Ultrices sagittis orci a scelerisque. Proin fermentum leo vel orci porta non. Sit amet nisl suscipit adipiscing. Aliquam etiam erat velit scelerisque in dictum. Elit ullamcorper dignissim cras tincidunt lobortis feugiat. Urna cursus eget nunc scelerisque viverra mauris in aliquam sem.

Congue eu consequat ac felis donec et. Nec nam aliquam sem et tortor. Cras semper auctor neque vitae tempus quam pellentesque nec nam. Fermentum dui faucibus in ornare quam. Nisi scelerisque eu ultrices vitae. Etiam tempor orci eu lobortis elementum nibh tellus molestie. Vitae sapien pellentesque habitant morbi tristique senectus et netus. Non odio euismod lacinia at quis. Venenatis cras sed felis eget. Tincidunt id aliquet risus feugiat in ante metus dictum. Aliquam sem et tortor consequat id porta. Urna id volutpat lacus laoreet non curabitur. In hendrerit gravida rutrum quisque non tellus orci. Est velit egestas dui id ornare arcu odio ut sem. Morbi tristique senectus et netus et malesuada. Integer malesuada nunc vel risus commodo viverra maecenas accumsan lacus. Diam quam nulla porttitor massa id neque aliquam vestibulum morbi. Nisi est sit amet facilisis. Metus aliquam eleifend mi in nulla posuere sollicitudin aliquam.

In nisl nisi scelerisque eu ultrices vitae. Donec enim diam vulputate ut pharetra. Pulvinar elementum integer enim neque volutpat. Nunc pulvinar sapien et ligula ullamcorper malesuada proin libero. In hac habitasse platea dictumst quisque sagittis purus sit. Donec ac odio tempor orci dapibus ultrices in. Pulvinar elementum integer enim neque volutpat ac tincidunt. Felis eget nunc lobortis mattis aliquam faucibus. Lectus vestibulum mattis ullamcorper velit sed ullamcorper morbi tincidunt. Dui nunc mattis enim ut tellus. Amet volutpat consequat mauris nunc congue nisi vitae suscipit. Leo integer malesuada nunc vel.]]