local _, addon = ...

local eofmarker = "\001"
local capany = "(.-)"
local capeol = "([#\n"..eofmarker.."])"
local cfind = "|c%x%x%x%x%x%x%x%x"
local rfind = "|r"

local colors = {
  pinkish = "FFC57991",
  orange = "FFCE9178",
  paleYellow = "FFDCCD79",
  yellow = "FFFFFF00",
  darkGreen = "FF6A8A35",
  darkBlue = "FF3F9CCA",
}

-- Coloring rules should be listed in reverse-priority order (highest prio color last)
local patterns = {
  { -- EOF
    pattern = "(.)$",
    result = "%1"..eofmarker
  },
  { -- Commands
    pattern = "(%w-):",
    result = "|c%1|r:",
    color = colors.darkBlue
  },
  { -- List item bullets
    pattern = [=[(%s-)(-)(%s-%S)]=],
    result = "%1|c%2|r%3",
    color = colors.yellow
  },
  -- { -- Flow style table braces
  --   pattern = [=[([{}])]=],
  --   result = "|c%1|r",
  --   color = colors.pinkish
  -- },
  -- { -- Clean comments before recoloring
  --   pattern = "#".."(.-)"..cfind.."(.-)"..rfind..capeol,
  --   result = "#%1%2%3",
  --   retry = false,
  -- },
  { -- Comments
    pattern = "#"..capany..capeol,
    result = "|c#%1|r%2",
    color = colors.darkGreen
  },
  { -- Remove EOF
    pattern = eofmarker,
    result = ""
  }
}
addon:catch(function()
  for _, p in ipairs(patterns) do
    if p.color then
      p.result = p.result:gsub("|c", "|c"..p.color)
    end
  end
end)

local function setIndentation(text)
  -- local lines = addon:SplitLines(text)
  -- for i, line in ipairs(lines) do

  -- end
  -- return addon:JoinLines(lines)
end

local function deColor(text)
  return text:gsub(cfind, ""):gsub(rfind, "")
end

local function setColors(text)
  for _, colorInfo in pairs(patterns) do
    local last = text
    repeat
      text = text:gsub(colorInfo.pattern, colorInfo.result)
      if colorInfo.retry then
        -- If "retry" is specified, then keep performing the substitution until it stops changing the text
        if last == text then
          break
        else
          last = text
        end
      end
    until not colorInfo.retry
  end

  return text
end

-- Given a block of text from an EditBox and the current position of the cursor (optional)
-- returns the highlighted version of the
function addon:ApplyYamlColors(text)
  text = deColor(text)
  text = setColors(text)
  return text
end

function addon:ApplyYamlIndentation(text)

end