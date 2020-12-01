local _, addon = ...

addon.QuestScriptTokens = {
  CMD_COMPLETE = "complete",
  CMD_OBJ = "objectives",
  CMD_QUEST = "quest",
  CMD_REC = "recommended",
  CMD_REQ = "required",
  CMD_START = "start",

  PARAM_AURA = "aura",
  PARAM_CHANNEL = "channel",
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
  PARAM_LANGUAGE = "language",
  PARAM_LEVEL = "level",
  PARAM_MESSAGE = "message",
  PARAM_NAME = "name",
  -- PARAM_REPUTATION = "reputation",
  -- PARAM_REPUTATION_NAME = "name",
  -- PARAM_REPUTATION_LEVEL = "level",
  PARAM_RECIPIENT = "recipient",
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