local _, addon = ...
local logger = addon.Logger:NewLogger("Localizer")

addon.QuestScriptLocalizer = {}

local localizables = {}
local rules -- defined below

-- If the condition value is a table of values, then returns each value in that table
-- in a reader-friendly comma-separated string, with the last two items separated by "or"
local function defaultConditionTextHandler(condVal)
  if condVal == nil then return end

  if type(condVal) == "table" then
    local len, result = addon:tlen(condVal), ""
    if len == 1 then
      for v in pairs(condVal) do
        result = v
      end
    elseif len > 1 then
      local i = 1
      for v in pairs(condVal) do
        if i == len then
          return result.." or "..v
        else
          result = result..", "..v
        end
        i = i + 1
      end
    end
    condVal = result
  end

  return condVal
end

local function parseConditionValueText(obj, handlerArg, handlerFn)
  local arg
  if handlerArg then
    arg = obj.conditions[handlerArg]
    -- If objective doesn't have a value for this condition, simply return nothing
    if not arg then return end
  else
    arg = obj
  end

  local result
  if handlerFn then
    result = handlerFn(arg)
  else
    if not handlerArg then
      logger:Warn("Failed to parse display text: a param name must be provided to use the default text handler")
      return
    end
    result = defaultConditionTextHandler(arg)
  end
  return result
end

local function populateDisplayText(text, obj)
  logger:Trace("=> received: %s", text)
  for _, mod in ipairs(rules.standard) do
    text = addon:strmod(text, mod.pattern, mod.fn, obj)
  end
  logger:Trace("<= resolved: %s", text)
  return text
end

-- Keep a ref to the bracketRule where other rules can grab it (assigned below)
local bracketRule

rules = {
  standard = {
    { -- Contents of bracketed sets are analyzed recursively, innermost first
      pattern = "%b[]",
      fn = function(str, obj)
        logger:Trace("     match: brackets %s", str)
        -- Extract contents from brackets
        str = str:match("^%[(.+)%]$")
        -- Recursively apply this function
        str = addon:strmod(str, bracketRule.pattern, bracketRule.fn, obj)

        local condition, valIfTrue, valIfFalse
        for _, br in ipairs(rules.bracketed) do
          -- Pattern returns up to three capture groups
          condition, valIfTrue, valIfFalse = str:match(br.pattern)
          if condition then
            -- If matched, an associated function will map to the appropriate values
            condition, valIfTrue, valIfFalse = br.fn(condition, valIfTrue, valIfFalse)
            logger:Trace("     ^ condition: %s, if-true: %s, if-false: %s", condition, valIfTrue, valIfFalse)
            break
          end
        end

        if not condition then
          -- Unable to parse bracket formula, try to parse the string as a whole
          logger:Trace("     ^ unmatched bracket formula")
          return populateDisplayText(str, obj)
        end

        -- Determine which text to parse next, based on condition's parsed value
        local ret
        condition = populateDisplayText(condition, obj)
        if condition and condition ~= "" then
          ret = valIfTrue
        else
          ret = valIfFalse
        end
        ret = ret or "" -- As a failsafe, never send nil to parse

        return populateDisplayText(ret, obj)
      end
    },
    { -- Any %var gets the value for the mapped condition returned
      pattern = "%%%w+",
      fn = function(pctstr, obj)
        logger:Trace("     match: var %s", pctstr)
        local template = localizables[obj.name]
        if not template then return pctstr end -- objective does not have any localizable content

        local str = pctstr:sub(2) -- Remove the leading %
        local handler
        local dt = localizables[obj.name].displaytext
        if dt and dt.vars then
          handler = dt.vars[str]
        end
        if not handler then return pctstr end -- objective has no displaytext handler for this var name

        -- Handlers under displaytext.vars[varname] can be registered in multiple ways, but two values are required:
        --   * fn: given some context, returns the value to be displayed (will be converted to string)
        --   * arg: a token name to define which param value should be passed to the fn
        -- This can be registed as a displaytext var in the following ways:
        --   * table: consisting of one or both of the above properties
        --   * string: the param name - a default handler fn will be used
        --   * function: a handler - the whole objective will be passed as a parameter
        local result
        if type(handler) == "table" then
          logger:Trace("     ^ handler: table (%s = %s)", pctstr, handler.arg)
          result = parseConditionValueText(obj, handler.arg, handler.fn)
        elseif type(handler) == "string" then
          logger:Trace("     ^ handler: string (%s = %s)", pctstr, handler)
          result = parseConditionValueText(obj, handler, nil)
        elseif type(handler) == "function" then
          logger:Trace("     ^ handler: function (%s)", pctstr)
          result = parseConditionValueText(obj, nil, handler)
        else
          logger:Trace("     ^ handler: not found (%s)", pctstr)
          result = pctstr
        end

        if result == nil then return "" end
        return tostring(result)
      end
    }
  },
  bracketed = {
    { -- If A, then show B, else show C
      pattern = "^(.-):(.-)|(.-)$",
      fn = function(a, b, c)
        logger:Trace("     ^ match: [a:b|c]")
        return a, b, c
      end
    },
    { -- If A, then show A, else show B
      pattern = "^(.-)|(.-)$",
      fn = function(a, b)
        logger:Trace("     ^ match: [a|b]")
        return a, a, b
      end
    },
    { -- If A, then show B, else show nothing
      pattern = "^(.-):(.-)$",
      fn = function(a, b)
        logger:Trace("     ^ match: [a:b]")
        return a, b, nil
      end
    },
    -- { -- If A and B, then show C, else show D
    --   pattern = "^(.-)&(.-):(.-)|(.-)",
    --   fn = function(a, b, c, d)
    --     return a and b, c, d
    --   end
    -- },
    -- { -- If A and B, then show C, else show nothing
    --   pattern = "^(.-)&(.-):(.-)$",
    --   fn = function(a, b, c)
    --     logger:Trace("     ^ match: [a&b:c]")
    --     return a and b, c, nil
    --   end
    -- },
    { -- If B, then show B with spacing A and C added, else show nothing
      pattern = "^([ ]-)([^ ]-)([ ]-)$",
      fn = function(a, b, c)
        return b, a..b..c, nil
      end
    }
  }
}

bracketRule = rules.standard[1]

--------------------
-- Public methods --
--------------------

-- Valid values for scope are: log [default], progress, quest, full
-- Use this method at runtime
function addon.QuestScriptLocalizer:GetDisplayText(obj, scope)
  scope = scope or "log"
  local displayText
  if obj.displaytext then
    -- Custom displayText is set for this instance of the objective
    displayText = obj.displaytext[scope]
  end
  if not displayText then
    -- Otherwise, use default displayText for this objective
    local dirTemplate = localizables[obj.name]
    assert(dirTemplate, "Invalid directive: "..obj.name)
    displayText = dirTemplate.displaytext[scope]
  end

  assert(displayText, "Cannot determine how to display text for directive: "..obj.name.." in scope "..scope)
  local text = populateDisplayText(displayText, obj)

  -- Clean up any leading, trailing, or duplicate spaces before returning
  return text:gsub("^%s+", ""):gsub("%s+$", ""):gsub(" +", " ")
end

-----------------------
-- Event Subscribers --
-----------------------

addon.AppEvents:Subscribe("QuestScriptLoaded", function()
  local queryHasDisplayText = function(cmd) return cmd.displaytext end
  localizables = addon.QuestScriptCompiler:Find(queryHasDisplayText)
  addon.AppEvents:Publish("LocalizerLoaded")
end)