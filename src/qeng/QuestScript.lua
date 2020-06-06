local _, addon = ...

local tokens = {
  COMMENT = "#",

  OBJ_EMOTE = "emote",
  OBJ_EMOTE_SCRIPT = "objective-emote",
  OBJ_EMOTE_TEXT = "objective-emote-display-text",
  OBJ_KILL = "kill",
  OBJ_KILL_SCRIPT = "objective-kill",
  OBJ_KILL_POST_SCRIPT = "objective-kill-after",
  OBJ_KILL_TEXT = "objective-kill-display-text",
  OBJ_TALKTO = "talkto",
  OBJ_TALKTO_ALIAS = "talk",
  OBJ_TALKTO_SCRIPT = "objective-talkto",
  OBJ_TALKTO_TEXT = "objective-talkto-display-text",

  COND_EMOTE = "emote",
  COND_EMOTE_ALIAS = "em",
  COND_EMOTE_SCRIPT = "condition-emote-message",
  COND_TARGET = "target",
  COND_TARGET_ALIAS = { "tar", "t" },
  COND_TARGET_KILL_SCRIPT = "condition-unique-kill-target",
  COND_TARGET_UNIT_SCRIPT = "condition-unique-unit-target",

  CMD_DEFINE = "define",
  CMD_DEFINE_ALIAS = "def",
  CMD_DEFINE_SCRIPT = "command-define",
  CMD_DESC = "description",
  CMD_DESC_SCRIPT = "command-description",
  CMD_FACTION = "faction",
  CMD_FACTION_SCRIPT = "command-faction",
  CMD_LEVEL = "level",
  CMD_LEVEL_SCRIPT = "command-level",
  CMD_LOC = "location",
  CMD_LOC_ALIAS = "loc",
  CMD_LOC_SCRIPT = "command-location",
  CMD_OBJ = "objective",
  CMD_OBJ_ALIAS = { "obj", "o" },
  CMD_OBJ_SCRIPT = "command-objective",
  CMD_QUEST = "quest",
  CMD_QUEST_SCRIPT = "command-quest",

  PARAM_DIFFICULTY = "difficulty",
  PARAM_DIFFICULTY_ALIAS = "diff",
  PARAM_GOAL = "goal",
  PARAM_GOAL_ALIAS = "g",
  PARAM_MAX = "max",
  PARAM_MIN = "min",
  PARAM_NAME = "name",
  PARAM_NAME_ALIAS = "n",
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
      ["BeforeCheckConditions"] = tokens.OBJ_EMOTE_SCRIPT,
      ["GetDisplayText"] = tokens.OBJ_EMOTE_TEXT,
    },
    params = {
      {
        name = tokens.COND_EMOTE,
        alias = tokens.COND_EMOTE_ALIAS,
        position = 1,
        required = true,
        multiple = true,
        scripts = {
          ["CheckCondition"] = tokens.COND_EMOTE_SCRIPT
        }
      },
      {
        name = tokens.COND_TARGET,
        alias = tokens.COND_TARGET_ALIAS,
        position = 2,
        multiple = true,
        scripts = {
          ["CheckCondition"] = tokens.COND_TARGET_UNIT_SCRIPT
        }
      },
    }
  },
  {
    name = tokens.OBJ_KILL,
    handler = tokens.OBJ_KILL_SCRIPT,
    text = tokens.OBJ_KILL_TEXT,
    scripts = {
      ["BeforeCheckConditions"] = tokens.OBJ_KILL_SCRIPT,
      ["AfterCheckConditions"] = tokens.OBJ_KILL_POST_SCRIPT,
      ["GetDisplayText"] = tokens.OBJ_KILL_TEXT,
    },
    params = {
      {
        name = tokens.COND_TARGET,
        alias = tokens.COND_TARGET_ALIAS,
        position = 1,
        required = true,
        multiple = true,
        scripts = {
          ["CheckCondition"] = tokens.COND_TARGET_KILL_SCRIPT
        }
      },
    }
  },
  {
    name = tokens.OBJ_TALKTO,
    alias = tokens.OBJ_TALKTO_ALIAS,
    scripts = {
      ["GetDisplayText"] = tokens.OBJ_TALKTO_TEXT,
    },
    params = {
      {
        name = tokens.COND_TARGET,
        alias = tokens.COND_TARGET_ALIAS,
        position = 1,
        required = true,
        multiple = true,
        scripts = {
          ["CheckCondition"] = tokens.COND_TARGET_UNIT_SCRIPT
        },
      }
    }
  }
}

local commands = {
  -- {
  --   name = tokens.CMD_DEFINE,
  --   alias = tokens.CMD_DEFINE_ALIAS,
  --   multiple = true,
  --   handler = tokens.CMD_DEFINE_SCRIPT,
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
      ["Run"] = tokens.CMD_QUEST_SCRIPT
    },
    params = {
      {
        name = tokens.PARAM_NAME,
        alias = tokens.PARAM_NAME_ALIAS,
        position = 1,
      }
    }
  },
  -- {
  --   name = tokens.CMD_DESC,
  --   alias = tokens.ALIAS_DESC,
  --   handler = tokens.CMD_DESC_SCRIPT,
  --   params = {
  --     {
  --       name = tokens.PARAM_TEXT,
  --       position = 1,
  --     }
  --   },
  -- },
  -- {
  --   name = tokens.CMD_LOC,
  --   alias = tokens.CMD_LOC_ALIAS,
  --   handler = tokens.CMD_LOC_SCRIPT,
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
  --   handler = tokens.CMD_LEVEL_SCRIPT,
  --   params = {
  --     {
  --       name = tokens.PARAM_DIFFICULTY,
  --       alias = tokens.PARAM_DIFFICULTY_ALIAS,
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
  --   handler = tokens.CMD_FACTION_SCRIPT,
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
    alias = tokens.CMD_OBJ_ALIAS,
    multiple = true,
    scripts = {
      ["Run"] = tokens.CMD_OBJ_SCRIPT
    },
    params = {
      {
        name = tokens.PARAM_NAME,
        position = 1,
        required = true,
      },
      {
        name = tokens.PARAM_GOAL,
        alias = tokens.PARAM_GOAL_ALIAS,
        position = 2,
        type = "number",
        default = 1,
      },
      {
        name = tokens.PARAM_TEXT,
        position = 3,
      }
    }
  }
}

addon.QuestScript = {
  tokens = tokens,
  objectives = objectives,
  commands = commands,
}
