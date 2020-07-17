local _, addon = ...

-- incrementing counter unique to a given objective
local incTable = {}
local function inc(obj)
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

addon.QuestScriptTokens = {
  OBJ_EMOTE = "emote",
  OBJ_EXPLORE = "explore",
  OBJ_KILL = "kill",
  OBJ_TALKTO = "talkto",

  CMD_COMPLETE = "complete",
  CMD_OBJ = "objectives",
  CMD_QUEST = "quest",
  CMD_REC = "recommended",
  CMD_REQ = "required",
  CMD_START = "start",

  METHOD_PARSE = "Parse",
  METHOD_PRE_EVAL = "BeforeEvaluate",
  METHOD_EVAL = "Evaluate",
  METHOD_POST_EVAL = "AfterEvaluate",

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
local t = addon.QuestScriptTokens

addon.QuestScriptTemplates = {
  -- Template for all top-level QuestScript fields
  ["toplevel"] = {
    scripts = {
      [t.METHOD_PARSE] = { required = true },
    }
  },
  -- Template for all quest objectives that will be tracked by the QuestEngine
  ["objective"] = {
    questEvent = true, -- Listen for QuestEvents by this name when the QuestEngine starts up
    contentParseable = true, -- Can be interpreted by ParseObjective
    multiple = true,
    displaytext = {
      vars = {
        ["g"] = function(obj) return obj.goal end,
        ["g2"] = function(obj) if obj.goal > 1 then return obj.goal end end,
        ["p"] = function(obj) return obj.progress end,
        ["p2"] = function(obj) if obj.progress < obj.goal then return obj.progress end end,
        ["inc"] = inc,
      }
    },
    scripts = {
      [t.METHOD_PRE_EVAL] = { required = false },
      [t.METHOD_POST_EVAL] = { required = false },
    },
    params = {
      [t.PARAM_TEXT] = {
        type = { "string", "table" },
      }
    }
  },
  -- Template for all conditions that can be evaluated against in-game data
  ["condition"] = {
    scripts = {
      [t.METHOD_EVAL] = { required = true },
    }
  },
  -- Template for start/complete objectives
  ["startcomplete"] = {
    template = { "toplevel" },
    contentParseable = true, -- Can be interpreted by ParseObjective
    scripts = {
      [t.METHOD_EVAL] = { required = true },
    },
    displaytext = {
      vars = {
        ["t"] = t.PARAM_TARGET,
        ["z"] = t.PARAM_ZONE,
        ["x"] = t.PARAM_POSX,
        ["y"] = t.PARAM_POSY,
        ["sz"] = t.PARAM_SUBZONE,
        ["r"] = t.PARAM_RADIUS,
      },
      log = "Go to [%t|[%x:Point #%inc]][[%t|%x]:[[%sz|%z]: in ]][%sz|%z]",
      quest = "Go to [%t|[%x:(%x, %y)]][[%t|%x]:[[%sz|%z]: in ]][%sz|%z]",
      full = "Go [%r:within %r units of|to] [%t:%t in :[%x:(%x, %y) in ]][%sz:%sz in ]%z"
    },
    params = {
      [t.PARAM_TEXT] = { type = { "string", "table" } },
      [t.PARAM_TARGET] = { template = "condition", multiple = true },
      [t.PARAM_ZONE] = { template = "condition" },
      [t.PARAM_SUBZONE] = { template = "condition" },
      [t.PARAM_POSX] = { template = "condition", type = "number" },
      [t.PARAM_POSY] = { template = "condition", type = "number" },
      [t.PARAM_RADIUS] = { type = "number" },
    }
  },
  -- Template for quest recommendations and requirements
  ["recreq"] = {
    template = { "toplevel" },
    scripts = {
      [t.METHOD_EVAL] = { required = true },
    },
    params = {
      [t.PARAM_CLASS] = {},
      [t.PARAM_FACTION] = {},
      [t.PARAM_LEVEL] = { type = "number" },
      -- todo: test nested params to make sure this is possible
      -- [tokens.PARAM_REPUTATION] = {
      --   params = {
      --     [tokens.PARAM_REPUTATION_NAME] = {
      --       required = true,
      --     },
      --     [tokens.PARAM_REPUTATION_LEVEL] = {
      --       required = true,
      --     }
      --   }
      -- }
    }
  }
}

local objectives = {
  [t.OBJ_EMOTE] = {
    template = "objective",
    shorthand = {
      t.PARAM_EMOTE,
      t.PARAM_GOAL,
      t.PARAM_TARGET,
    },
    displaytext = {
      vars = {
        ["em"] = t.PARAM_EMOTE,
        ["t"] = t.PARAM_TARGET,
      },
      log = "/%em[%t: with %t][%g2: %p/%g]",
      progress = "/%em[%t: with %t]: %p/%g",
      quest = "/%em[%t: with [%g2]%t|[%g2: %g2 times]]",
      full = "Use emote /%em[%t: on [%g2]%t|[%g2: %g2 times]]"
    },
    params = {
      [t.PARAM_GOAL] = { type = "number" },
      [t.PARAM_EMOTE] = {
        template = "condition",
        required = true,
        multiple = true,
      },
      [t.PARAM_TARGET] = {
        template = "condition",
        multiple = true,
      },
    }
  },
  [t.OBJ_EXPLORE] = {
    template = "objective",
    shorthand = {
      t.PARAM_ZONE,
      t.PARAM_SUBZONE,
      t.PARAM_POSX,
      t.PARAM_POSY,
      t.PARAM_RADIUS,
    },
    displaytext = {
      vars = {
        ["z"] = t.PARAM_ZONE,
        ["x"] = t.PARAM_POSX,
        ["y"] = t.PARAM_POSY,
        ["sz"] = t.PARAM_SUBZONE,
        ["r"] = t.PARAM_RADIUS,
      },
      log = "Go to [%x:Point #%inc in ][%sz|%z]",
      progress = "[%x:Point #%inc in ][%sz|%z] explored: %p/%g",
      quest = "Explore [%x:Point #%inc in ][%sz:%sz in ]%z",
      full = "Go [%r:within %r units of|to] [%x:(%x, %y) in ][%sz:%sz in ]%z"
    },
    params = {
      [t.PARAM_ZONE] = { template = "condition" },
      [t.PARAM_SUBZONE] = { template = "condition" },
      [t.PARAM_POSX] = { template = "condition", type = "number" },
      [t.PARAM_POSY] = { template = "condition", type = "number" },
      [t.PARAM_RADIUS] = { type = "number" },
    }
  },
  [t.OBJ_KILL] = {
    template = "objective",
    shorthand = {
      t.PARAM_GOAL,
      t.PARAM_TARGET,
    },
    displaytext = {
      vars = {
        ["t"] = t.PARAM_KILLTARGET,
      },
      log = "%t %p/%g",
      progress = "%t slain: %p/%g",
      quest = "Kill [%g2]%t",
      full = "Kill [%g2]%t"
    },
    params = {
      [t.PARAM_GOAL] = { type = "number" },
      [t.PARAM_KILLTARGET] = {
        alias = t.PARAM_TARGET,
        template = "condition",
        required = true,
        multiple = true,
      },
    }
  },
  [t.OBJ_TALKTO] = {
    template = "objective",
    shorthand = {
      t.PARAM_GOAL,
      t.PARAM_TARGET,
    },
    displaytext = {
      vars = {
        ["t"] = t.PARAM_TARGET,
      },
      log = "Talk to %t[%g2: %p/%g]",
      progress = "Talk to %t: %p/%g",
      quest = "Talk to [%g2]%t",
      full = "Talk to [%g2]%t"
    },
    params = {
      [t.PARAM_GOAL] = { type = "number" },
      [t.PARAM_TARGET] = {
        template = "condition",
        required = true,
        multiple = true,
      }
    }
  }
}

addon.QuestScript = {
  [t.CMD_QUEST] = {
    template = "toplevel",
    params = {
      [t.PARAM_NAME] = {},
      [t.PARAM_DESCRIPTION] = {},
      [t.PARAM_COMPLETION] = {},
    }
  },
  [t.CMD_OBJ] = {
    template = "toplevel",
    params = objectives,
  },

  [t.CMD_REC] = { template = "recreq" },
  [t.CMD_REQ] = { template = "recreq" },

  [t.CMD_START] = { template = "startcomplete" },
  [t.CMD_COMPLETE] = { template = "startcomplete" },
}
