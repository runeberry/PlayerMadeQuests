local _, addon = ...

addon.QuestScriptTokens = {
  OBJ_AURA = "gain-aura",
  OBJ_EMOTE = "use-emote",
  OBJ_EQUIP = "equip-item",
  OBJ_EXPLORE = "explore",
  OBJ_KILL = "kill",
  OBJ_TALKTO = "talk-to",

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

  PARAM_AURA = "aura",
  PARAM_CLASS = "class",
  PARAM_COMPLETION = "completion",
  PARAM_COORDS = "coords",
  PARAM_DESCRIPTION = "description",
  PARAM_EMOTE = "emote",
  PARAM_EQUIP = "equip",
  PARAM_FACTION = "faction",
  PARAM_GOAL = "goal",
  PARAM_ITEM = "item",
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

local parameters = {
  [t.PARAM_GOAL] = {
    type = "number"
  },
}

-- Returns the parameter from the above table with any optional modifications applied
local function getParameter(paramName, mod)
  if not parameters[paramName] then
    addon.Logger:Error("Failed to load QuestScript data: unrecognized parameter %s", paramName)
    return
  end
  local param = addon:CopyTable(parameters[paramName])
  if mod then
    param = addon:MergeTable(param, mod)
  end
  return param
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
  -- Template for all objectives that can be limited by coordinate, zone, and/or subzone conditions
  ["coordobj"] = {
    template = { "objective" },
    conditions = {
      t.PARAM_ZONE,
      t.PARAM_SUBZONE,
      t.PARAM_COORDS,
    },
  },
  -- Template for all conditions that can be evaluated against in-game data
  ["condition"] = {},
  -- Template for start/complete objectives
  ["startcomplete"] = {
    template = { "toplevel" },
    contentParsable = true, -- Can be interpreted by ParseObjective
    scripts = {
      [t.METHOD_EVAL] = { required = true },
    },
    displaytext = {
      log = "Go to %t[%sz:[%t: at] %sz|[%z:[%t: in] %z]]",
      quest = "Go to [%t ][%atin ]%xyz[%a: while having %a]",
      full = "Go to [%t ][%atin ]%xyrz[%a: while having %a]"
    },
    params = {
      [t.PARAM_TEXT] = { type = { "string", "table" } },
    },
    conditions = {
      t.PARAM_AURA,
      t.PARAM_TARGET,
      t.PARAM_ZONE,
      t.PARAM_SUBZONE,
      t.PARAM_COORDS,
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
  [t.OBJ_AURA] = {
    template = "coordobj",
    shorthand = {
      t.PARAM_AURA,
    },
    displaytext = {
      log = "Gain %a",
      progress = "%a gained",
      quest = "Gain the %a aura[%xyz: while in %xyz][%i: while having %i][%e: while wearing %e]",
      full = "Gain the %a aura[%xyz: while in %xyrz][%i: while having %i][%e: while wearing %e]"
    },
    conditions = {
      { name = t.PARAM_AURA, required = true },
      t.PARAM_EQUIP,
      t.PARAM_ITEM,
    }
  },
  [t.OBJ_EMOTE] = {
    template = "coordobj",
    shorthand = {
      t.PARAM_EMOTE,
      t.PARAM_GOAL,
      t.PARAM_TARGET,
    },
    displaytext = {
      log = "/%em[%t: with %t][%g2: %p/%g]",
      progress = "/%em[%t: with %t]: %p/%g",
      quest = "/%em[%t: with [%g2 ]%t|[%g2: %g2 times]][%xysz: in %xysz][%a: while having %a][%i: while having %i][%e: while wearing %e]",
      full = "Use emote /%em[%t: on [%g2 ]%t|[%g2: %g2 times]][%xyz: in %xyrz][%a: while having %a][%i: while having %i][%e: while wearing %e]"
    },
    params = {
      [t.PARAM_GOAL] = getParameter(t.PARAM_GOAL),
    },
    conditions = {
      t.PARAM_AURA,
      { name = t.PARAM_EMOTE, { required = true } },
      t.PARAM_EQUIP,
      t.PARAM_ITEM,
      t.PARAM_TARGET,
    }
  },
  [t.OBJ_EQUIP] = {
    template = "coordobj",
    shorthand = {
      t.PARAM_EQUIP,
    },
    displaytext = {
      log = "Equip %e",
      progress = "%e equipped",
      quest = "Equip %e[%xyz: while in %xyz][%a: while having %a][%i: while having %i]",
      full = "Equip %e[%xyz: while in %xyrz][%a: while having %a][%i: while having %i]"
    },
    conditions = {
      t.PARAM_AURA,
      { name = t.PARAM_EQUIP, required = true },
      t.PARAM_ITEM,
    }
  },
  [t.OBJ_EXPLORE] = {
    template = "coordobj",
    shorthand = {
      t.PARAM_ZONE,
      t.PARAM_COORDS,
    },
    displaytext = {
      log = "Go to %xysz",
      progress = "%xysz explored: %p/%g",
      quest = "Explore %xyz[%a: while having %a][%i: while having %i][%e: while wearing %e]",
      full = "Go to %xyrz[%a: while having %a][%i: while having %i][%e: while wearing %e]"
    },
    conditions = {
      t.PARAM_AURA,
      t.PARAM_EQUIP,
      t.PARAM_ITEM,
    }
  },
  [t.OBJ_KILL] = {
    template = "coordobj",
    shorthand = {
      t.PARAM_GOAL,
      t.PARAM_TARGET,
    },
    displaytext = {
      log = "%t %p/%g",
      progress = "%t slain: %p/%g",
      quest = "Kill [%g2 ]%t[%xyz: in %xyz][%a: while having %a][%i: while having %i][%e: while wearing %e]",
      full = "Kill [%g2 ]%t[%xyz: in %xyrz][%a: while having %a][%i: while having %i][%e: while wearing %e]"
    },
    params = {
      [t.PARAM_GOAL] = getParameter(t.PARAM_GOAL),
    },
    conditions = {
      t.PARAM_AURA,
      t.PARAM_EQUIP,
      t.PARAM_ITEM,
      { name = t.PARAM_KILLTARGET, alias = t.PARAM_TARGET, required = true },
    }
  },
  [t.OBJ_TALKTO] = {
    template = "coordobj",
    shorthand = {
      t.PARAM_GOAL,
      t.PARAM_TARGET,
    },
    displaytext = {
      log = "Talk to %t[%g2: %p/%g]",
      progress = "Talk to %t: %p/%g",
      quest = "Talk to [%g2 ]%t[%xyz: in %xyz][%a: while having %a][%i: while having %i][%e: while wearing %e]",
      full = "Talk to [%g2 ]%t[%xyz: in %xyrz][%a: while having %a][%i: while having %i][%e: while wearing %e]"
    },
    params = {
      [t.PARAM_GOAL] = getParameter(t.PARAM_GOAL),
    },
    conditions = {
      t.PARAM_AURA,
      t.PARAM_EQUIP,
      t.PARAM_ITEM,
      { name = t.PARAM_TARGET, required = true },
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
