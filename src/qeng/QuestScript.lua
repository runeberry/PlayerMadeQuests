local _, addon = ...

local tokens = {
  COMMENT = "#",

  OBJ_EMOTE = "emote",
  OBJ_KILL = "kill",
  OBJ_TALKTO = "talkto",

  COND_EMOTE = "emote",
  COND_TARGET = "target",

  CMD_DEFINE = "define",
  CMD_DESC = "description",
  CMD_FACTION = "faction",
  CMD_LEVEL = "level",
  CMD_LOC = "location",
  CMD_OBJ = "objective",
  CMD_QUEST = "quest",

  METHOD_PARSE = "Parse",
  METHOD_PRE_COND = "BeforeCheckConditions",
  METHOD_CHECK_COND = "CheckCondition",
  METHOD_POST_COND = "AfterCheckConditions",
  METHOD_DISPLAY_TEXT = "GetDisplayText",

  PARAM_DESCRIPTION = "description",
  PARAM_DIFFICULTY = "difficulty",
  PARAM_GOAL = "goal",
  PARAM_MAX = "max",
  PARAM_MIN = "min",
  PARAM_NAME = "name",
  PARAM_SIDE = "side",
  PARAM_TEXT = "text",
  PARAM_VARNAME = "varname",
  PARAM_X = "x",
  PARAM_Y = "y",
  PARAM_Z = "z",
  PARAM_ZONE = "zone",

  FLAG_REQUIRED = "required",
  FLAG_RECOMMENDED = "recommended",
}

local objectives = {
  {
    name = tokens.OBJ_EMOTE,
    scripts = {
      tokens.METHOD_PRE_COND,
      tokens.METHOD_DISPLAY_TEXT,
    },
    params = {
      {
        name = tokens.COND_EMOTE,
        alias = "em",
        position = 1,
        required = true,
        multiple = true,
        scripts = {
          tokens.METHOD_CHECK_COND,
        }
      },
      {
        name = tokens.COND_TARGET,
        alias = { "tar", "t" },
        position = 2,
        multiple = true,
        scripts = {
          tokens.METHOD_CHECK_COND,
        }
      },
    }
  },
  {
    name = tokens.OBJ_KILL,
    scripts = {
      tokens.METHOD_PRE_COND,
      tokens.METHOD_POST_COND,
      tokens.METHOD_DISPLAY_TEXT,
    },
    params = {
      {
        name = tokens.COND_TARGET,
        alias = { "tar", "t" },
        position = 1,
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
    alias = "talk",
    scripts = {
      tokens.METHOD_DISPLAY_TEXT,
    },
    params = {
      {
        name = tokens.COND_TARGET,
        alias = { "tar", "t" },
        position = 1,
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
    scripts = {
      tokens.METHOD_PARSE,
    },
    params = {
      {
        name = tokens.PARAM_NAME,
        alias = "n",
        position = 1,
      },
      {
        name = tokens.PARAM_DESCRIPTION,
        alias = "desc",
        position = 2,
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
    alias = { "obj", "o" },
    scripts = {
      tokens.METHOD_PARSE,
    },
    params = {
      {
        name = tokens.PARAM_NAME,
        position = 1,
        required = true,
      },
      {
        name = tokens.PARAM_GOAL,
        alias = "g",
        position = 2,
        type = "number",
      },
      {
        name = tokens.PARAM_TEXT,
      }
    }
  }
}

addon.QuestScript = {
  tokens = tokens,
  objectives = objectives,
  commands = commands,
}
