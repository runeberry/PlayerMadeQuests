local _, addon = ...

local tokens = {
  OBJ_EMOTE = "emote",
  OBJ_EXPLORE = "explore",
  OBJ_KILL = "kill",
  OBJ_TALKTO = "talkto",

  CMD_DEFINE = "define",
  CMD_DESC = "description",
  CMD_FACTION = "faction",
  CMD_LEVEL = "level",
  CMD_LOC = "location",
  CMD_OBJ = "objectives",
  CMD_QUEST = "quest",

  METHOD_PARSE = "Parse",
  METHOD_PRE_COND = "BeforeCheckConditions",
  METHOD_CHECK_COND = "CheckCondition",
  METHOD_POST_COND = "AfterCheckConditions",
  METHOD_DISPLAY_TEXT = "GetDisplayText",

  PARAM_DESCRIPTION = "description",
  PARAM_DIFFICULTY = "difficulty",
  PARAM_EMOTE = "emote",
  PARAM_GOAL = "goal",
  PARAM_MAX = "max",
  PARAM_MIN = "min",
  PARAM_NAME = "name",
  PARAM_POSX = "posx",
  PARAM_POSY = "posy",
  PARAM_RADIUS = "radius",
  PARAM_SIDE = "side",
  PARAM_SUBZONE = "subzone",
  PARAM_TARGET = "target",
  PARAM_TEXT = "text",
  PARAM_VARNAME = "varname",
  PARAM_ZONE = "zone",

  FLAG_REQUIRED = "required",
  FLAG_RECOMMENDED = "recommended",
}

local globalDisplayTextVars = {
  ["g"] = function(obj) return obj.goal end,
  ["g2"] = function(obj) if obj.goal > 1 then return obj.goal end end,
  ["p"] = function(obj) return obj.progress end,
  ["p2"] = function(obj) if obj.progress < obj.goal then return obj.progress end end,
  ["inc"] = function(obj) -- incrementing counter tied to this objective, only works after quest is built
    if obj._inc then return obj._inc end
    if not obj._quest then return 0 end
    obj._quest._inc = obj._quest._inc or 0
    obj._quest._inc = obj._quest._inc + 1
    obj._inc = obj._quest._inc
    return obj._inc
  end
}

local objectives = {
  {
    name = tokens.OBJ_EMOTE,
    shorthand = {
      tokens.PARAM_EMOTE,
      tokens.PARAM_GOAL,
      tokens.PARAM_TARGET,
    },
    scripts = {
      tokens.METHOD_PRE_COND,
      tokens.METHOD_DISPLAY_TEXT,
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
      tokens.METHOD_PRE_COND,
      tokens.METHOD_POST_COND,
      tokens.METHOD_DISPLAY_TEXT,
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
      { -- todo: remove goal from explore, should always be 1
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
        name = tokens.PARAM_SUBZONE,
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
    scripts = {
      tokens.METHOD_PRE_COND,
      tokens.METHOD_POST_COND,
      tokens.METHOD_DISPLAY_TEXT,
    },
    displaytext = {
      vars = {
        ["t"] = tokens.PARAM_TARGET,
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
        name = tokens.PARAM_TARGET,
        required = true,
        multiple = true,
        scripts = {
          tokens.METHOD_CHECK_COND,
        }
      },
    }
  },
  {
    name = tokens.OBJ_TALKTO,
    shorthand = {
      tokens.PARAM_GOAL,
      tokens.PARAM_TARGET,
    },
    scripts = {
      tokens.METHOD_DISPLAY_TEXT,
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
  -- {
  --   name = tokens.CMD_DEFINE,
  --   alias = "def",
  --   multiple = true,
  --   params = {
  --     {
  --       name = tokens.PARAM_VARNAME,
  --       position = 1,
  --       required = true,
  --     }
  --   }
  -- },
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
      }
    }
  },
  -- {
  --   name = tokens.CMD_DESC,
  --   alias = "desc",
  --   params = {
  --     {
  --       name = tokens.PARAM_TEXT,
  --       position = 1,
  --     }
  --   },
  -- },
  -- {
  --   name = tokens.CMD_LOC,
  --   alias = "loc",
  --   params = {
  --     {
  --       name = tokens.PARAM_ZONE,
  --       position = 1,
  --       type = { "number", "string" },
  --       required = true,
  --     },
  --     {
  --       name = tokens.PARAM_X,
  --       position = 2,
  --       type = "number",
  --     },
  --     {
  --       name = tokens.PARAM_Y,
  --       position = 3,
  --       type = "number",
  --     },
  --     {
  --       name = tokens.PARAM_Z,
  --       position = 4,
  --       type = "number",
  --     },
  --   }
  -- },
  -- {
  --   name = tokens.CMD_LEVEL,
  --   params = {
  --     {
  --       name = tokens.PARAM_DIFFICULTY,
  --       alias = "diff",
  --       position = 1,
  --       type = "number",
  --     },
  --     {
  --       name = tokens.PARAM_MIN,
  --       type = "number",
  --     },
  --     {
  --       name = tokens.PARAM_MAX,
  --       type = "number",
  --     }
  --   },
  --   flags = {
  --     tokens.FLAG_REQUIRED,
  --     tokens.FLAG_RECOMMENDED,
  --   }
  -- },
  -- {
  --   name = tokens.CMD_FACTION,
  --   params = {
  --     {
  --       name = tokens.PARAM_SIDE,
  --       position = 1,
  --       required = true,
  --     }
  --   },
  --   flags = {
  --     tokens.FLAG_REQUIRED,
  --     tokens.FLAG_RECOMMENDED,
  --   }
  -- },
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
  }
}

addon.QuestScript = {
  tokens = tokens,
  objectives = objectives,
  commands = commands,
  globalDisplayTextVars = globalDisplayTextVars,
}
