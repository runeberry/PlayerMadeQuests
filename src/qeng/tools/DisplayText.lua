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
local defaultConditionTextHandler

--- Gets the value at the associated condition/parameter name
local function getParamVal(cp, name)
  return (cp.conditions and cp.conditions[name]) or (cp.parameters and cp.parameters[name])
end

--- Wraps the handler in a check for the specified parameter
local function ifParam(name, fn)
  return function(cp)
    local param = getParamVal(cp, name)
    if param then
      return fn(param, cp)
    end
  end
end

local function pluralize(str)
  return addon:Pluralize(2, str)
end
local function getClassNames(classId)
  return addon:GetClassNameById(classId)
end
local function addGuildBackets(str) return string.format("<%s>", str) end
local function clean(str)
  -- Clean up any leading, trailing, or duplicate spaces before returning
  return str:gsub("^%s+", ""):gsub("%s+$", ""):gsub(" +", " "):gsub("\n ", "\n")
end

vars = {
  ----------------
  -- Conditions --
  ----------------

  ["a"] = t.PARAM_AURA,
  ["ch"] = t.PARAM_CHANNEL,
  ["co"] = t.PARAM_COORDS,
  ["e"] = t.PARAM_EQUIP,
  ["em"] = t.PARAM_EMOTE,
  ["i"] = t.PARAM_ITEM,
  ["lang"] = t.PARAM_LANGUAGE,
  ["msg"] = t.PARAM_MESSAGE,
  ["player"] = t.PARAM_PLAYER,
  ["rc"] = t.PARAM_REWARDCHOICE,
  ["tn"] = { t.PARAM_TARGET, t.PARAM_KILLTARGET, t.PARAM_SPELLTARGET, t.PARAM_RECIPIENT },
  ["tc"] = function(cp)
    local targetClassId = cp.conditions[t.PARAM_TARGETCLASS]
      or cp.conditions[t.PARAM_KILLTARGETCLASS]
      or cp.conditions[t.PARAM_SPELLTARGETCLASS]
    return targetClassId and addon:GetClassNameById(targetClassId)
  end,
  ["tf"] = function(cp)
    local targetFactionId = cp.conditions[t.PARAM_TARGETFACTION]
      or cp.conditions[t.PARAM_KILLTARGETFACTION]
      or cp.conditions[t.PARAM_SPELLTARGETFACTION]
    return targetFactionId and addon:GetFactionNameById(targetFactionId)
  end,
  ["tg"] = { t.PARAM_TARGETGUILD, t.PARAM_KILLTARGETGUILD, t.PARAM_SPELLTARGETGUILD },
  ["tl"] = { t.PARAM_TARGETLEVEL, t.PARAM_KILLTARGETLEVEL, t.PARAM_SPELLTARGETLEVEL },
  ["st"] = t.PARAM_SAMETARGET,
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
  ["r"] = ifParam(t.PARAM_COORDS, function(coords) return coords.radius end),
  --- x of coords
  ["x"] = ifParam(t.PARAM_COORDS, function(coords) return coords.x end),
  --- (x, y)
  ["xy"] = ifParam(t.PARAM_COORDS, function(coords) return addon:PrettyCoords(coords.x, coords.y) end),
  --- (x, y) +/- r
  ["xyr"] = ifParam(t.PARAM_COORDS, function(coords) return addon:PrettyCoords(coords.x, coords.y, coords.radius) end),
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
  ["y"] = ifParam(t.PARAM_COORDS, function(coords) return coords.y end),
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
  ["s"] = function(cp)
    local spell = cp.conditions[t.PARAM_SPELL]
    if not spell then return "[spell]" end

    local spellNames = {}
    for spellId in pairs(spell) do
      local spellInfo = addon:LookupSpellSafe(spellId)
      local spellName = (spellInfo and spellInfo.name) or string.format("[Spell: %i]", spellId)
      spellNames[spellName] = true
    end

    return defaultConditionTextHandler(spellNames)
  end,
  -- Returns a descriptive name of the matching objective target(s)
  ["t"] = function(cp)
    local targetName = cp.conditions[t.PARAM_TARGET] or cp.conditions[t.PARAM_KILLTARGET] or cp.conditions[t.PARAM_SPELLTARGET] or cp.conditions[t.PARAM_RECIPIENT]
    if targetName then
      -- "Player1, Player2, or Player3"
      return defaultConditionTextHandler(targetName)
    end

    local targetLevel = cp.conditions[t.PARAM_TARGETLEVEL] or cp.conditions[t.PARAM_KILLTARGETLEVEL] or cp.conditions[t.PARAM_SPELLTARGETLEVEL]
    local targetFaction = cp.conditions[t.PARAM_TARGETFACTION] or cp.conditions[t.PARAM_KILLTARGETFACTION] or cp.conditions[t.PARAM_SPELLTARGETFACTION]
    local targetGuild = cp.conditions[t.PARAM_TARGETGUILD] or cp.conditions[t.PARAM_KILLTARGETGUILD] or cp.conditions[t.PARAM_SPELLTARGETGUILD]
    local targetClass = cp.conditions[t.PARAM_TARGETCLASS] or cp.conditions[t.PARAM_KILLTARGETCLASS] or cp.conditions[t.PARAM_SPELLTARGETCLASS]

    if not targetLevel and not targetFaction and not targetClass and not targetGuild then
      return
    end

    local strModifier
    if cp.goal and cp.goal > 1 then
      strModifier = pluralize
    end

    if targetLevel then
      -- "Level 60+..."
      targetLevel = string.format("Level %i+", targetLevel)
    end

    -- "...Horde..."

    if targetGuild then
      -- "...<Guild1>, <Guild2> or <Guild3>..."
      targetGuild = defaultConditionTextHandler(targetGuild, addGuildBackets)
    end

    if targetClass then
      -- "...Hunter, Shaman or Paladin..." or "...Hunters, Shamans or Paladins..."
      targetClass = defaultConditionTextHandler(targetClass, getClassNames)
    elseif targetGuild then
      -- "...member" or "...members"
      targetClass = defaultConditionTextHandler("member", strModifier)
    else
      -- "...foe" or "...foes"
      targetClass = defaultConditionTextHandler("foe", strModifier)
    end

    -- Extra whitespace will be trimmed when the final string is cleaned
    return string.format("%s %s %s %s", targetLevel or "", targetFaction or "", targetGuild or "", targetClass or "")
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

  ["name"] = function() return addon:GetPlayerName(true) end,
  ["class"] = function() return addon:GetPlayerClass(true) end,
  ["race"] = function() return addon:GetPlayerRace(true) end,
  ["guild"] = function() return addon:GetPlayerGuildName() end,
  -- Use as a sex conditional flag, e.g. [%gen:his|her]
  ["gen"] = function() return addon:GetPlayerSex() == 2 or nil end,

  --------------------
  -- Quest-specific --
  --------------------

  -- Inserts the name of the player who wrote the quest
  ["author"] = function(quest)
    if quest.metadata then
      return quest.metadata.authorName
    else
      -- In case we arrived here from a non-quest context
      return "%author"
    end
  end,
  -- Inserts the name of the player who shared the quest
  ["giver"] = function(quest)
    if quest.metadata then
      -- Use player name if there was no giver
      return quest.metadata.giverName or addon:GetPlayerName()
    else
      -- In case we arrived here from a non-quest context
      return "%giver"
    end
  end,

  ----------------
  -- Formatting --
  ----------------

  ["n"] = function() return "\n" end,
  ["br"] = function() return "\n\n" end,
}

-- If the condition value is a table of values, then returns each value in that table
-- in a reader-friendly comma-separated string, with the last two items separated by "or"
defaultConditionTextHandler = function(condVal, modifier)
  if condVal == nil then
    logger:Trace("     ^ condition: value is nil")
    return
  end

  if type(condVal) == "table" then
    local len, result = addon:tlen(condVal), ""
    if len == 1 then
      logger:Trace("     ^ condition: value is 1 distinct item")
      for v in pairs(condVal) do
        if modifier then v = modifier(v) end
        result = v
      end
    elseif len > 1 then
      local i = 1
      for v in pairs(condVal) do
        if modifier then v = modifier(v) end
        if i == 1 then
          result = v
        elseif i == 2 then
          result = v.." or "..result
        else
          result = v..", "..result
        end
        i = i + 1
      end
      logger:Trace("     ^ condition: value is %i distinct items", i)
    end
    condVal = result
  else
    logger:Trace("     ^ condition: value is type %s", type(condVal))

    if modifier then condVal = modifier(condVal) end
  end

  return condVal
end

local function parseParamValueText(cp, handlerArg, handlerFn)
  local arg
  if handlerArg then
    arg = getParamVal(cp, handlerArg)
    -- If objective doesn't have a value for this condition, simply return nothing
    if not arg then
      logger:Trace("     ^ No value for parameter: %s", handlerArg)
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

  local i, prevText = 0, nil
  while prevText ~= text and i < 9 do
    -- Apply all substitution rules to the text until it no longer changes
    -- Failsafe: avoid inf loop by capping at 9 iterations
    i = i + 1
    prevText = text
    for _, mod in ipairs(rules.standard) do
      text = addon:strmod(text, mod.pattern, mod.fn, obj)
    end
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
            result = parseParamValueText(obj, var, nil)
            if result and result ~= "" then
              logger:Trace("   ^ handler: string (%s = %s)", pctstr, var)
              break
            end
          end
        elseif type(handler) == "table" then
          logger:Trace("   ^ handler: table (%s = %s)", pctstr, handler.arg)
          result = parseParamValueText(obj, handler.arg, handler.fn)
        elseif type(handler) == "string" then
          logger:Trace("   ^ handler: string (%s = %s)", pctstr, handler)
          result = parseParamValueText(obj, handler, nil)
        elseif type(handler) == "function" then
          logger:Trace("   ^ handler: function (%s)", pctstr)
          result = parseParamValueText(obj, nil, handler)
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

  return clean(text)
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