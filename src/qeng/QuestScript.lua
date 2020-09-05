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

addon.QuestScript = {
  [t.CMD_QUEST] = {
    type = "table",
    properties = {
      ["name"] = { type = "string" },
      ["description"] = { type = "string" },
      ["completion"] = { type = "string" },
    },
  },
  [t.CMD_OBJ] = {
    type = "array",
    properties = {
      type = { "string", "table" },
      properties = {
        [t.PARAM_GOAL] = { type = "number" },
        [t.PARAM_TEXT] = { type = "string" },
      },
    }
  },
  [t.CMD_REC] = {
    type = "table",
    properties = {
      [t.PARAM_TEXT] = { type = "string" },
    }
  },
  [t.CMD_REQ] = {
    type = "table",
    properties = {
      [t.PARAM_TEXT] = { type = "string" },
    }
  },
  [t.CMD_START] = {
    type = "table",
    properties = {
      [t.PARAM_TEXT] = { type = "string" },
    }
  },
  [t.CMD_COMPLETE] = {
    type = "table",
    properties = {
      [t.PARAM_TEXT] = { type = "string" },
    }
  },
}