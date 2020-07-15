local _, addon = ...

local tokens = {
  OBJ_COMPLETE = "complete",
  OBJ_EMOTE = "emote",
  OBJ_EXPLORE = "explore",
  OBJ_KILL = "kill",
  OBJ_START = "start",
  OBJ_TALKTO = "talkto",

  CMD_COMPLETE = "complete",
  CMD_OBJ = "objectives",
  CMD_QUEST = "quest",
  CMD_REC = "recommended",
  CMD_REQ = "required",
  CMD_START = "start",

  METHOD_PARSE = "Parse",
  METHOD_PRE_COND = "BeforeCheckConditions",
  METHOD_CHECK_COND = "CheckCondition",
  METHOD_POST_COND = "AfterCheckConditions",

  PARAM_CLASS = "class",
  PARAM_COMPLETION = "completion",
  PARAM_DESCRIPTION = "description",
  PARAM_EMOTE = "emote",
  PARAM_FACTION = "faction",
  PARAM_GOAL = "goal",
  PARAM_KILLTARGET = "killtarget",
  PARAM_LEVEL = "level",
  PARAM_NAME = "name",
  PARAM_POSX = "posx",
  PARAM_POSY = "posy",
  PARAM_RADIUS = "radius",
  -- PARAM_REPUTATION = "reputation",
  -- PARAM_REPUTATION_NAME = "name",
  -- PARAM_REPUTATION_LEVEL = "level",
  PARAM_SUBZONE = "subzone",
  PARAM_TARGET = "target",
  PARAM_TEXT = "text",
  PARAM_ZONE = "zone",
}

local incTable = {}

local globalDisplayTextVars = {
  ["g"] = function(obj) return obj.goal end,
  ["g2"] = function(obj) if obj.goal > 1 then return obj.goal end end,
  ["p"] = function(obj) return obj.progress end,
  ["p2"] = function(obj) if obj.progress < obj.goal then return obj.progress end end,
  ["inc"] = function(obj) -- incrementing counter tied to this objective, only works after quest is built
    local qinc = incTable[obj.questId]
    if not qinc then
      qinc = {}
      incTable[obj.questId] = qinc
    end

    local incVal = qinc[obj.id]
    if not incVal then
      incVal = addon:tlen(qinc) + 1
      qinc[obj.id] = incVal
    end

    return incVal
  end
}

local function startCompleteParams()
  return {
    {
      name = tokens.PARAM_TEXT,
      type = { "string", "table" }
    },
    {
      name = tokens.PARAM_TARGET,
      multiple = true,
      scripts = {
        tokens.METHOD_CHECK_COND,
      }
    },
    {
      name = tokens.PARAM_ZONE,
      scripts = {
        tokens.METHOD_CHECK_COND
      }
    },
    {
      name = tokens.PARAM_SUBZONE,
      scripts = {
        tokens.METHOD_CHECK_COND
      }
    },
    {
      name = tokens.PARAM_POSX,
      type = "number",
      scripts = {
        tokens.METHOD_CHECK_COND
      }
    },
    {
      name = tokens.PARAM_POSY,
      type = "number",
      scripts = {
        tokens.METHOD_CHECK_COND
      }
    },
    {
      name = tokens.PARAM_RADIUS,
      type = "number",
    },
  }
end

local function reqParams()
  return {
    {
      name = tokens.PARAM_CLASS,
    },
    {
      name = tokens.PARAM_FACTION,
    },
    {
      name = tokens.PARAM_LEVEL,
      type = "number"
    },
    -- todo: test nested params to make sure this is possible
    -- {
    --   name = tokens.PARAM_REPUTATION,
    --   params = {
    --     {
    --       name = tokens.PARAM_REPUTATION_NAME,
    --       required = true,
    --     },
    --     {
    --       name = tokens.PARAM_REPUTATION_LEVEL,
    --       required = true,
    --     }
    --   }
    -- }
  }
end

local objectives = {
  {
    name = tokens.OBJ_COMPLETE,
    command = true, -- Only used to evaluate the "complete" command
    displaytext = {
      vars = {
        ["t"] = tokens.PARAM_TARGET,
        ["z"] = tokens.PARAM_ZONE,
        ["x"] = tokens.PARAM_POSX,
        ["y"] = tokens.PARAM_POSY,
        ["sz"] = tokens.PARAM_SUBZONE,
        ["r"] = tokens.PARAM_RADIUS,
      },
      log = "Go to [%t|[%x:Point #%inc]][[%t|%x]:[[%sz|%z]: in ]][%sz|%z]",
      quest = "Go to [%t|[%x:(%x, %y)]][[%t|%x]:[[%sz|%z]: in ]][%sz|%z]",
      full = "Go [%r:within %r units of|to] [%t:%t in :[%x:(%x, %y) in ]][%sz:%sz in ]%z"
    },
    params = startCompleteParams()
  },
  {
    name = tokens.OBJ_EMOTE,
    shorthand = {
      tokens.PARAM_EMOTE,
      tokens.PARAM_GOAL,
      tokens.PARAM_TARGET,
    },
    displaytext = {
      vars = {
        ["em"] = tokens.PARAM_EMOTE,
        ["t"] = tokens.PARAM_TARGET,
      },
      log = "/%em[%t: with %t][%g2: %p/%g]",
      progress = "/%em[%t: with %t]: %p/%g",
      quest = "/%em[%t: with [%g2]%t|[%g2: %g2 times]]",
      full = "Use emote /%em[%t: on [%g2]%t|[%g2: %g2 times]]"
    },
    params = {
      {
        name = tokens.PARAM_GOAL,
        type = "number",
        default = 1
      },
      {
        name = tokens.PARAM_TEXT,
        type = { "string", "table" }
      },
      {
        name = tokens.PARAM_EMOTE,
        required = true,
        multiple = true,
        scripts = {
          tokens.METHOD_CHECK_COND,
        }
      },
      {
        name = tokens.PARAM_TARGET,
        multiple = true,
        scripts = {
          tokens.METHOD_CHECK_COND,
        }
      },
    }
  },
  {
    name = tokens.OBJ_EXPLORE,
    shorthand = {
      tokens.PARAM_ZONE,
      tokens.PARAM_SUBZONE,
      tokens.PARAM_POSX,
      tokens.PARAM_POSY,
      tokens.PARAM_RADIUS,
    },
    scripts = {
      tokens.METHOD_POST_COND,
    },
    displaytext = {
      vars = {
        ["z"] = tokens.PARAM_ZONE,
        ["x"] = tokens.PARAM_POSX,
        ["y"] = tokens.PARAM_POSY,
        ["sz"] = tokens.PARAM_SUBZONE,
        ["r"] = tokens.PARAM_RADIUS,
      },
      log = "Go to [%x:Point #%inc in ][%sz|%z]",
      progress = "[%x:Point #%inc in ][%sz|%z] explored: %p/%g",
      quest = "Explore [%x:Point #%inc in ][%sz:%sz in ]%z",
      full = "Go [%r:within %r units of|to] [%x:(%x, %y) in ][%sz:%sz in ]%z"
    },
    params = {
      { -- todo: (#51) remove goal from explore, should always be 1
        -- https://github.com/dolphinspired/PlayerMadeQuests/issues/51
        name = tokens.PARAM_GOAL,
        type = "number",
        default = 1
      },
      {
        name = tokens.PARAM_TEXT,
        type = { "string", "table" }
      },
      {
        name = tokens.PARAM_ZONE,
        scripts = {
          tokens.METHOD_CHECK_COND
        }
      },
      {
        name = tokens.PARAM_SUBZONE,
        scripts = {
          tokens.METHOD_CHECK_COND
        }
      },
      {
        name = tokens.PARAM_POSX,
        type = "number",
        scripts = {
          tokens.METHOD_CHECK_COND
        }
      },
      {
        name = tokens.PARAM_POSY,
        type = "number",
        scripts = {
          tokens.METHOD_CHECK_COND
        }
      },
      {
        name = tokens.PARAM_RADIUS,
        type = "number",
      },
    }
  },
  {
    name = tokens.OBJ_KILL,
    shorthand = {
      tokens.PARAM_GOAL,
      tokens.PARAM_TARGET,
    },
    displaytext = {
      vars = {
        ["t"] = tokens.PARAM_KILLTARGET,
      },
      log = "%t %p/%g",
      progress = "%t slain: %p/%g",
      quest = "Kill [%g2]%t",
      full = "Kill [%g2]%t"
    },
    params = {
      {
        name = tokens.PARAM_GOAL,
        type = "number",
        default = 1
      },
      {
        name = tokens.PARAM_TEXT,
        type = { "string", "table" }
      },
      {
        name = tokens.PARAM_KILLTARGET,
        alias = tokens.PARAM_TARGET,
        required = true,
        multiple = true,
        scripts = {
          tokens.METHOD_CHECK_COND,
        }
      },
    }
  },
  {
    name = tokens.OBJ_START,
    command = true, -- Only used to evaluate the "start" command
    displaytext = {
      vars = {
        ["t"] = tokens.PARAM_TARGET,
        ["z"] = tokens.PARAM_ZONE,
        ["x"] = tokens.PARAM_POSX,
        ["y"] = tokens.PARAM_POSY,
        ["sz"] = tokens.PARAM_SUBZONE,
        ["r"] = tokens.PARAM_RADIUS,
      },
      log = "Go to [%t|[%x:Point #%inc]][[%t|%x]:[[%sz|%z]: in ]][%sz|%z]",
      quest = "Go to [%t|[%x:(%x, %y)]][[%t|%x]:[[%sz|%z]: in ]][%sz|%z]",
      full = "Go [%r:within %r units of|to] [%t:%t in :[%x:(%x, %y) in ]][%sz:%sz in ]%z"
    },
    params = startCompleteParams()
  },
  {
    name = tokens.OBJ_TALKTO,
    shorthand = {
      tokens.PARAM_GOAL,
      tokens.PARAM_TARGET,
    },
    displaytext = {
      vars = {
        ["t"] = tokens.PARAM_TARGET,
      },
      log = "Talk to %t[%g2: %p/%g]",
      progress = "Talk to %t: %p/%g",
      quest = "Talk to [%g2]%t",
      full = "Talk to [%g2]%t"
    },
    params = {
      {
        name = tokens.PARAM_GOAL,
        type = "number",
        default = 1
      },
      {
        name = tokens.PARAM_TEXT,
        type = { "string", "table" }
      },
      {
        name = tokens.PARAM_TARGET,
        required = true,
        multiple = true,
        scripts = {
          tokens.METHOD_CHECK_COND,
        },
      }
    }
  }
}

local commands = {
  {
    name = tokens.CMD_COMPLETE,
    scripts = {
      tokens.METHOD_PARSE,
    },
    params = startCompleteParams()
  },
  {
    name = tokens.CMD_QUEST,
    shorthand = { tokens.PARAM_NAME, tokens.PARAM_DESCRIPTION },
    scripts = {
      tokens.METHOD_PARSE,
    },
    params = {
      {
        name = tokens.PARAM_NAME,
      },
      {
        name = tokens.PARAM_DESCRIPTION,
      },
      {
        name = tokens.PARAM_COMPLETION,
      },
    }
  },
  {
    name = tokens.CMD_OBJ,
    scripts = {
      tokens.METHOD_PARSE,
    },
    params = {
      {
        name = tokens.PARAM_NAME,
        required = true,
      },
    }
  },
  {
    name = tokens.CMD_REC,
    scripts = {
      tokens.METHOD_PARSE,
      tokens.METHOD_CHECK_COND,
    },
    params = reqParams(),
  },
  {
    name = tokens.CMD_REQ,
    scripts = {
      tokens.METHOD_PARSE,
      tokens.METHOD_CHECK_COND,
    },
    params = reqParams(),
  },
  {
    name = tokens.CMD_START,
    scripts = {
      tokens.METHOD_PARSE,
    },
    params = startCompleteParams()
  }
}

addon.QuestScript = {
  tokens = tokens,
  objectives = objectives,
  commands = commands,
  globalDisplayTextVars = globalDisplayTextVars,
}
