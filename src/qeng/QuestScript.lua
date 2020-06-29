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

local spec = [[
  quest:
    name: "string"
    description: "string"
  objectives:
    - kill 5 Chicken # [1] = "kill 5 Chicken"
    - kill: 5 Chicken # [2] = { kill = "5 Chicken" }
    - kill: # [3] = { kill = yaml.null, goal = 5, target = "Chicken" }
      goal: 5
      target: Chicken
    - kill: # [4] = { kill = { goal = 5, target = "Chicken" } }
        goal: 5
        target: Chicken
    - kill: { goal: 5, target: Chicken } # [5] = same as [4]
]]

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
    params = {
      {
        name = tokens.PARAM_GOAL,
        type = "number",
        default = 1
      },
      {
        name = tokens.PARAM_TEXT,
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
    params = {
      {
        name = tokens.PARAM_GOAL,
        type = "number",
        default = 1
      },
      {
        name = tokens.PARAM_TEXT,
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
    params = {
      {
        name = tokens.PARAM_GOAL,
        type = "number",
        default = 1
      },
      {
        name = tokens.PARAM_TEXT,
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
    params = {
      {
        name = tokens.PARAM_GOAL,
        type = "number",
        default = 1
      },
      {
        name = tokens.PARAM_TEXT,
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
}
