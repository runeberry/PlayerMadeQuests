local _, addon = ...

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
  PARAM_COORDS = "coords",
  PARAM_DESCRIPTION = "description",
  PARAM_EMOTE = "emote",
  PARAM_FACTION = "faction",
  PARAM_GOAL = "goal",
  PARAM_KILLTARGET = "killtarget",
  PARAM_LEVEL = "level",
  PARAM_NAME = "name",
  -- PARAM_REPUTATION = "reputation",
  -- PARAM_REPUTATION_NAME = "name",
  -- PARAM_REPUTATION_LEVEL = "level",
  PARAM_SUBZONE = "subzone",
  PARAM_TARGET = "target",
  PARAM_TEXT = "text",
  PARAM_ZONE = "zone",
}
local t = addon.QuestScriptTokens

-- Common displaytext functions
local getGoal = function(obj) return obj.goal end
local getGoal2 = function(obj) if obj.goal > 1 then return obj.goal end end
local getProgress = function(obj) return obj.progress end
local getProgress2 = function(obj) if obj.progress < obj.goal then return obj.progress end end

local getX = function(coords) if coords then return coords.x end end
local getY = function(coords) if coords then return coords.y end end
local getRad = function(coords) if coords then return coords.radius end end
local getXY = function(coords) if coords then return addon:PrettyCoords(coords.x, coords.y) end end
local getXYR = function(coords) if coords then return addon:PrettyCoords(coords.x, coords.y, coords.radius) end end

local getZone2 = function(obj)
  local zone = obj.conditions[t.PARAM_ZONE]
  local subzone = obj.conditions[t.PARAM_SUBZONE]
  if zone and subzone then
    return subzone.." in "..zone
  elseif zone then
    return zone
  else
    return subzone
  end
end
local getXYZ = function(obj)
  local zone = getZone2(obj) or ""
  local coords = getXY(obj.conditions[t.PARAM_COORDS])
  if not coords then return zone end
  return coords.." in "..zone
end
local getXYRZ = function(obj)
  local zone = getZone2(obj) or ""
  local coords = getXYR(obj.conditions[t.PARAM_COORDS])
  if not coords then return zone end
  return coords.." in "..zone
end
local getAtin = function(obj)
  local target = obj.conditions[t.PARAM_TARGET]
  if not target then return end
  local zone = obj.conditions[t.PARAM_ZONE]
  local subzone = obj.conditions[t.PARAM_SUBZONE]
  local coords = obj.conditions[t.PARAM_COORDS]
  if coords or subzone then
    return "at"
  elseif zone then
    return "in"
  end
end

-- incrementing counter unique to a given objective
local incTable = {}
local function getInc(obj)
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
    contentParsable = true, -- Can be interpreted by ParseObjective
    multiple = true,
    displaytext = {
      vars = {
        ["g"] = getGoal,
        ["g2"] = getGoal2,
        ["p"] = getProgress,
        ["p2"] = getProgress2,
        ["inc"] = getInc,
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
  ["coordtext"] = {
    displaytext = {
      vars = {
        ["co"] = t.PARAM_COORDS,
        ["z"] = t.PARAM_ZONE,
        ["sz"] = t.PARAM_SUBZONE,
        ["x"] = { arg = t.PARAM_COORDS, fn = getX },
        ["y"] = { arg = t.PARAM_COORDS, fn = getY },
        ["r"] = { arg = t.PARAM_COORDS, fn = getRad },
        ["xy"] = { arg = t.PARAM_COORDS, fn = getXY },
        ["xyz"] = getXYZ,
        ["xyr"] = { arg = t.PARAM_COORDS, fn = getXYR },
        ["xyrz"] = getXYRZ,
        ["z2"] = getZone2,
        ["atin"] = getAtin,
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
    template = { "toplevel", "coordtext" },
    contentParsable = true, -- Can be interpreted by ParseObjective
    scripts = {
      [t.METHOD_EVAL] = { required = true },
    },
    displaytext = {
      vars = {
        ["t"] = t.PARAM_TARGET,
      },
      log = "Go to %t[%sz:[%t: at] %sz|[%z:[%t: in] %z]]",
      quest = "Go to [%t ][%atin ]%xyz",
      full = "Go to [%t ][%atin ]%xyrz"
    },
    params = {
      [t.PARAM_TEXT] = { type = { "string", "table" } },
      [t.PARAM_TARGET] = {
        template = "condition",
        scripts = {
          [t.METHOD_PARSE] = { required = true },
        },
        multiple = true,
      },
      [t.PARAM_ZONE] = { template = "condition" },
      [t.PARAM_SUBZONE] = { template = "condition" },
      [t.PARAM_COORDS] = {
        template = "condition",
        scripts = {
          [t.METHOD_PARSE] = { required = true },
        },
      },
    }
  },
  -- Template for quest recommendations and requirements
  ["recreq"] = {
    template = { "toplevel" },
    contentParsable = true,
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
      quest = "/%em[%t: with [%g2 ]%t|[%g2: %g2 times]]",
      full = "Use emote /%em[%t: on [%g2 ]%t|[%g2: %g2 times]]"
    },
    params = {
      [t.PARAM_GOAL] = { type = "number" },
      [t.PARAM_EMOTE] = {
        template = "condition",
        scripts = {
          [t.METHOD_PARSE] = { required = true },
        },
        required = true,
        multiple = true,
      },
      [t.PARAM_TARGET] = {
        template = "condition",
        scripts = {
          [t.METHOD_PARSE] = { required = true },
        },
        multiple = true,
      },
    }
  },
  [t.OBJ_EXPLORE] = {
    template = { "objective", "coordtext" },
    shorthand = {
      t.PARAM_ZONE,
      t.PARAM_COORDS,
    },
    displaytext = {
      log = "Go to [%co:Point #%inc in ][%sz|%z]",
      progress = "[%co:Point #%inc in ][%sz|%z] explored: %p/%g",
      quest = "Explore [%co:Point #%inc in ]%z2",
      full = "Go to %xyrz"
    },
    params = {
      [t.PARAM_ZONE] = { template = "condition" },
      [t.PARAM_SUBZONE] = { template = "condition" },
      [t.PARAM_COORDS] = {
        template = "condition",
        scripts = {
          [t.METHOD_PARSE] = { required = true },
        },
      },
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
      quest = "Kill [%g2 ]%t",
      full = "Kill [%g2 ]%t"
    },
    params = {
      [t.PARAM_GOAL] = { type = "number" },
      [t.PARAM_KILLTARGET] = {
        alias = t.PARAM_TARGET,
        template = "condition",
        scripts = {
          [t.METHOD_PARSE] = { required = true },
        },
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
      quest = "Talk to [%g2 ]%t",
      full = "Talk to [%g2 ]%t"
    },
    params = {
      [t.PARAM_GOAL] = { type = "number" },
      [t.PARAM_TARGET] = {
        template = "condition",
        scripts = {
          [t.METHOD_PARSE] = { required = true },
        },
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
