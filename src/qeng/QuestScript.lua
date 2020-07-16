local _, addon = ...

local tokens = {
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

local templates = {
  ["parsed"] = {
    scripts = {
      [tokens.METHOD_PARSE] = { required = true },
    }
  },
  ["objective"] = {
    objective = true, -- Explicitly mark objectives so they can be evaluated during quest progression
    scripts = {
      [tokens.METHOD_PRE_COND] = { required = false },
      [tokens.METHOD_POST_COND] = { required = false },
    },
    params = {
      [tokens.PARAM_TEXT] = {
        type = { "string", "table" },
      }
    }
  },
  ["evaluated"] = {
    scripts = {
      [tokens.METHOD_CHECK_COND] = { required = true },
    }
  },
  ["startcomplete"] = {
    template = { "parsed", "evaluated" },
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
    params = {
      [tokens.PARAM_TEXT] = { type = { "string", "table" } },
      [tokens.PARAM_TARGET] = { template = "evaluated", multiple = true },
      [tokens.PARAM_ZONE] = { template = "evaluated" },
      [tokens.PARAM_SUBZONE] = { template = "evaluated" },
      [tokens.PARAM_POSX] = { template = "evaluated", type = "number" },
      [tokens.PARAM_POSY] = { template = "evaluated", type = "number" },
      [tokens.PARAM_RADIUS] = { type = "number" },
    }
  },
  ["requirement"] = {
    template = { "parsed", "evaluated" },
    params = {
      [tokens.PARAM_CLASS] = {},
      [tokens.PARAM_FACTION] = {},
      [tokens.PARAM_LEVEL] = { type = "number" },
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
  [tokens.OBJ_EMOTE] = {
    template = "objective",
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
      [tokens.PARAM_GOAL] = { type = "number" },
      [tokens.PARAM_EMOTE] = {
        template = "evaluated",
        required = true,
        multiple = true,
      },
      [tokens.PARAM_TARGET] = {
        template = "evaluated",
        multiple = true,
      },
    }
  },
  [tokens.OBJ_EXPLORE] = {
    template = "objective",
    shorthand = {
      tokens.PARAM_ZONE,
      tokens.PARAM_SUBZONE,
      tokens.PARAM_POSX,
      tokens.PARAM_POSY,
      tokens.PARAM_RADIUS,
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
      [tokens.PARAM_ZONE] = { template = "evaluated" },
      [tokens.PARAM_SUBZONE] = { template = "evaluated" },
      [tokens.PARAM_POSX] = { template = "evaluated", type = "number" },
      [tokens.PARAM_POSY] = { template = "evaluated", type = "number" },
      [tokens.PARAM_RADIUS] = { type = "number" },
    }
  },
  [tokens.OBJ_KILL] = {
    template = "objective",
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
      [tokens.PARAM_GOAL] = { type = "number" },
      [tokens.PARAM_KILLTARGET] = {
        alias = tokens.PARAM_TARGET,
        template = "evaluated",
        required = true,
        multiple = true,
      },
    }
  },
  [tokens.OBJ_TALKTO] = {
    template = "objective",
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
      [tokens.PARAM_GOAL] = { type = "number" },
      [tokens.PARAM_TARGET] = {
        template = "evaluated",
        required = true,
        multiple = true,
      }
    }
  }
}

local commands = {
  [tokens.CMD_COMPLETE] = { template = "startcomplete" },
  [tokens.CMD_QUEST] = {
    template = "parsed",
    params = {
      [tokens.PARAM_NAME] = {},
      [tokens.PARAM_DESCRIPTION] = {},
      [tokens.PARAM_COMPLETION] = {},
    }
  },
  [tokens.CMD_OBJ] = {
    template = "parsed",
    params = {
      [tokens.PARAM_NAME] = { required = true },
    }
  },
  [tokens.CMD_REC] = { template = "requirement" },
  [tokens.CMD_REQ] = { template = "requirement" },
  [tokens.CMD_START] = { template = "startcomplete" },
}

addon.QuestScript = {
  tokens = tokens,
  templates = templates,
  objectives = objectives,
  commands = commands,
  globalDisplayTextVars = globalDisplayTextVars,
}
