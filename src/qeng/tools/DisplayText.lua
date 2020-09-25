local _, addon = ...
local logger = addon.Logger:NewLogger("DisplayText")
local assertf, errorf = addon.assertf, addon.errorf
local t = addon.QuestScriptTokens

local checkpoints = addon.QuestEngine.definitions.checkpoints

-- These vars are defined below, but need a reference up here
-- to be in scope for all functions that use them
local rules
local bracketRule
local vars

--- Wraps the handler in a check for the specified parameter
local function ifCond(name, fn)
  return function(cp)
    local param = cp.conditions and cp.conditions[name]
    if param then
      return fn(param, cp)
    end
  end
end

vars = {
  ----------------
  -- Conditions --
  ----------------

  ["a"] = t.PARAM_AURA,
  ["co"] = t.PARAM_COORDS,
  ["e"] = t.PARAM_EQUIP,
  ["em"] = t.PARAM_EMOTE,
  ["i"] = t.PARAM_ITEM,
  ["t"] = { t.PARAM_TARGET, t.PARAM_KILLTARGET },
  ["sz"] = t.PARAM_SUBZONE,
  ["z"] = t.PARAM_ZONE,

  -----------------------------
  -- Derived from Conditions --
  -----------------------------

  --- Decides whether to display "at" or "in" based on context
  ["atin"] = function(cp)
    local target = cp.conditions[t.PARAM_TARGET]
    if not target then return end
    local zone = cp.conditions[t.PARAM_ZONE]
    local subzone = cp.conditions[t.PARAM_SUBZONE]
    local coords = cp.conditions[t.PARAM_COORDS]
    if coords or subzone then
      return "at"
    elseif zone then
      return "in"
    end
  end,
  --- radius of coords
  ["r"] = ifCond(t.PARAM_COORDS, function(coords) return coords.radius end),
  --- x of coords
  ["x"] = ifCond(t.PARAM_COORDS, function(coords) return coords.x end),
  --- (x, y)
  ["xy"] = ifCond(t.PARAM_COORDS, function(coords) return addon:PrettyCoords(coords.x, coords.y) end),
  --- (x, y) +/- r
  ["xyr"] = ifCond(t.PARAM_COORDS, function(coords) return addon:PrettyCoords(coords.x, coords.y, coords.radius) end),
  --- (x, y) +/- r in zone
  ["xyrz"] = function(cp)
    local zone = vars["z2"](cp) or ""
    local coords = vars["xyr"](cp)
    if not coords then return zone end
    return coords.." in "..zone
  end,
  ["xysz"] = function(cp)
    local subzone = cp.conditions[t.PARAM_SUBZONE] or cp.conditions[t.PARAM_ZONE] or ""
    local coords = vars["xy"](cp)
    if not coords then return subzone end
    return coords.." in "..subzone
  end,
  --- (x, y) in zone
  ["xyz"] = function(cp)
    local zone = vars["z2"](cp) or ""
    local coords = vars["xy"](cp)
    if not coords then return zone end
    return coords.." in "..zone
  end,
  --- y of coords
  ["y"] = ifCond(t.PARAM_COORDS, function(coords) return coords.y end),
  --- zone in subzone
  ["z2"] = function(cp)
    local zone = cp.conditions[t.PARAM_ZONE]
    local subzone = cp.conditions[t.PARAM_SUBZONE]
    if zone and subzone then
      return subzone.." in "..zone
    elseif zone then
      return zone
    else
      return subzone
    end
  end,

  ------------------------
  -- Objective-specific --
  ------------------------

  ["g"] = function(obj) return obj.goal end,
  ["g2"] = function(obj) if obj.goal > 1 then return obj.goal end end,
  ["p"] = function(obj) return obj.progress end,
  ["p2"] = function(obj) if obj.progress < obj.goal then return obj.progress end end,

  -----------------
  -- Player Info --
  -----------------

  ["name"] = function() return addon:GetPlayerName() end,
  ["class"] = function() return addon:GetPlayerClass() end,
  ["race"] = function() return addon:GetPlayerRace() end,
  -- Use as a gender conditional flag, e.g. [%gen:his|her]
  ["gen"] = function() return (addon:GetPlayerGender() == "male") or nil end,

  --------------------
  -- Quest-specific --
  --------------------

  -- Inserts the name of the player who wrote the quest
  ["author"] = function(quest) return quest.metadata.authorName end,
  -- Inserts the name of the player who shared the quest, or the player's name if not found
  ["giver"] = function(quest)
    local catalogItem = addon.QuestCatalog:FindByID(quest.questId)
    if catalogItem and catalogItem.from and catalogItem.from.name and catalogItem.from.source == addon.QuestCatalogSource.Shared then
      return catalogItem.from.name
    end
    return addon:GetPlayerName()
  end,

  ----------------
  -- Formatting --
  ----------------

  ["n"] = function() return "\n" end,
  ["br"] = function() return "\n\n" end,
}

-- If the condition value is a table of values, then returns each value in that table
-- in a reader-friendly comma-separated string, with the last two items separated by "or"
local function defaultConditionTextHandler(condVal)
  if condVal == nil then
    logger:Trace("     ^ condition: value is nil")
    return
  end

  if type(condVal) == "table" then
    local len, result = addon:tlen(condVal), ""
    if len == 1 then
      logger:Trace("     ^ condition: value is 1 distinct item")
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
      logger:Trace("     ^ condition: value is %i distinct items", i)
    end
    condVal = result
  else
    logger:Trace("     ^ condition: value is type %s", type(condVal))
  end

  return condVal
end

local function parseConditionValueText(cp, handlerArg, handlerFn)
  local arg
  if handlerArg then
    arg = cp.conditions[handlerArg]
    -- If objective doesn't have a value for this condition, simply return nothing
    if not arg then
      logger:Trace("     ^ No value for condition: %s", handlerArg)
      return
    end
  else
    arg = cp
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

rules = {
  standard = {
    { -- Contents of bracketed sets are analyzed recursively, innermost first
      pattern = "%b[]",
      fn = function(str, obj)
        logger:Trace("   match: brackets %s", str)
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
            logger:Trace("   ^ condition: %s, if-true: %s, if-false: %s", tostring(condition), tostring(valIfTrue), tostring(valIfFalse))
            break
          end
        end

        if not condition then
          -- Unable to parse bracket formula, try to parse the string as a whole
          logger:Trace("   ^ unmatched bracket formula")
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
        logger:Trace("   match: var %s", pctstr)

        local str = pctstr:sub(2) -- Remove the leading %
        local handler = vars[str]
        if not handler then
          logger:Trace("   ^ No handler found for this key")
          return pctstr
        end -- no displaytext handler for this var name

        -- Handlers under vars[varname] can be registered in multiple ways, but two values are required:
        --   * fn: given some context, returns the value to be displayed (will be converted to string)
        --   * arg: a token name to define which param value should be passed to the fn
        -- This can be registed as a displaytext var in the following ways:
        --   * table: consisting of one or both of the above properties
        --   * string: the param name - a default handler fn will be used
        --   * function: a handler - the whole objective will be passed as a parameter
        local result
        if type(handler) == "table" and handler[1] then
          -- todo: This is sort of a hack to allow multiple params to be used for the same var.
          -- Consider replacing this with a method to allow the objective to override its default var
          -- definitions with ones of its own.
          for _, var in ipairs(handler) do
            result = parseConditionValueText(obj, var, nil)
            if result and result ~= "" then
              logger:Trace("   ^ handler: string (%s = %s)", pctstr, var)
              break
            end
          end
        elseif type(handler) == "table" then
          logger:Trace("   ^ handler: table (%s = %s)", pctstr, handler.arg)
          result = parseConditionValueText(obj, handler.arg, handler.fn)
        elseif type(handler) == "string" then
          logger:Trace("   ^ handler: string (%s = %s)", pctstr, handler)
          result = parseConditionValueText(obj, handler, nil)
        elseif type(handler) == "function" then
          logger:Trace("   ^ handler: function (%s)", pctstr)
          result = parseConditionValueText(obj, nil, handler)
        else
          logger:Trace("   ^ handler: not found (%s)", pctstr)
          result = pctstr
        end

        if result == nil then
          logger:Trace("     ^ No result returned from handler")
          return ""
        end
        return tostring(result)
      end
    }
  },
  bracketed = {
    { -- If A, then show B, else show C
      pattern = "^(.-):(.-)|(.-)$",
      fn = function(a, b, c)
        logger:Trace("   ^ match: [a:b|c]")
        return a, b, c
      end
    },
    { -- If A, then show A, else show B
      pattern = "^(.-)|(.-)$",
      fn = function(a, b)
        logger:Trace("   ^ match: [a|b]")
        return a, a, b
      end
    },
    { -- If A, then show B, else show nothing
      pattern = "^(.-):(.-)$",
      fn = function(a, b)
        logger:Trace("   ^ match: [a:b]")
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

function addon:PopulateText(str, context)
  if not str then return "" end
  context = context or {}

  local text = populateDisplayText(str, context)

  -- Clean up any leading, trailing, or duplicate spaces before returning
  return text:gsub("^%s+", ""):gsub("%s+$", ""):gsub(" +", " "):gsub("\n ", "\n")
end

-- Valid values for scope are: log [default], progress, quest, full
-- Use this method at runtime
function addon:GetCheckpointDisplayText(cp, scope)
  scope = scope or "log"
  local displayText
  if cp.parameters and cp.parameters.text then
    -- Custom displayText is set for this instance of the objective
    displayText = cp.parameters.text[scope]
  end
  if not displayText then
    -- Otherwise, use default displayText for this objective
    local checkpoint = checkpoints[cp.name]
    assertf(checkpoint, "Unknown checkpoint: %s", cp.name)
    assertf(checkpoint.parameters and checkpoint.parameters.text and checkpoint.parameters.text.defaultValue,
      "Checkpoint '%s' does not have any default display text to use", checkpoint.name)
    displayText = checkpoint.parameters.text.defaultValue[scope]
  end

  assertf(displayText, "Cannot determine how to display text for checkpoint '%s' in scope: %s ", cp.name, tostring(scope))
  return addon:PopulateText(displayText, cp)
end