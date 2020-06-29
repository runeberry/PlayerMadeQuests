local _, addon = ...

local bofmarker = "\001"
local eofmarker = "\002"
local capbol = "([\n"..bofmarker.."])"
local capeol = "([\n"..eofmarker.."])"
local cfind = "|c%x%x%x%x%x%x%x%x"
local rfind = "|r"

local mods = {}

local colors = {
  pinkish = "FFC57991",
  orange = "FFFF8000",
  paleYellow = "FFDCCD79",
  yellow = "FFFFFF00",
  darkGreen = "FF6A8A35",
  darkBlue = "FF3F9CCA",
}

local patterns = {
  { -- BOF/EOF
    pattern = "^(.-)$",
    result = bofmarker.."%1"..eofmarker
  },
  {
    pattern = capbol.."(%s-)(%w-):",
    result = "%1%2|c%3|r:",
    color = colors.darkBlue
  },
  { -- List item keys
    pattern = capbol.."(%s-)(-) (%w-)(:?)([%s\n])",
    result = "%1%2%3 |c%4|r%5%6",
    color = colors.orange
  },
  { -- List item bullets
    pattern = capbol.."(%s-)(-)",
    result = "%1%2|c%3|r",
    color = colors.yellow
  },
  { -- Flow style table braces
    pattern = "([{}])",
    result = "|c%1|r",
    color = colors.pinkish
  },
  { -- Comments
    pattern = "#(.-)"..capeol,
    mod = "ColorComments",
    color = colors.darkGreen
  },
  { -- Remove BOF/EOF
    pattern = bofmarker.."(.-)"..eofmarker,
    result = "%1"
  }
}
addon:catch(function()
  for _, p in ipairs(patterns) do
    if p.color and p.result then
      p.result = p.result:gsub("|c", "|c"..p.color)
    end
  end
end)

local function deColor(text)
  return text:gsub(cfind, ""):gsub(rfind, "")
end

-- strmod functions - for when gsub isn't enough
mods["ColorComments"] = function(comment, color)
  return "|c"..color..deColor(comment).."|r"
end

local function setColors(text)
  for i, colorInfo in pairs(patterns) do
    if colorInfo.result then
      text = text:gsub(colorInfo.pattern, colorInfo.result)
    elseif colorInfo.mod then
      text = addon:strmod(text, colorInfo.pattern, mods[colorInfo.mod], colorInfo.color)
    end
  end

  return text
end

-- Given a block of text from an EditBox, returns the syntax-highlighted
-- version of that text
function addon:ApplyYamlColors(text)
  text = deColor(text)
  text = setColors(text)
  return text
end

function addon:ApplyYamlIndentation(text)

end