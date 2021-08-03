local _, addon = ...

addon.QuestScriptTokens = {
  CMD_CHAIN = "chain",
  CMD_COMPLETE = "complete",
  CMD_OBJ = "objectives",
  CMD_QUEST = "quest",
  CMD_REC = "recommended",
  CMD_REQ = "required",
  CMD_REWARDS = "rewards",
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
  PARAM_KILLTARGETCLASS = "killtargetclass",
  PARAM_KILLTARGETFACTION = "killtargetfaction",
  PARAM_KILLTARGETGUILD = "killtargetguild",
  PARAM_KILLTARGETLEVEL = "killtargetlevel",
  PARAM_LANGUAGE = "language",
  PARAM_LEVEL = "level",
  PARAM_MESSAGE = "message",
  PARAM_MONEY = "money",
  PARAM_NAME = "name",
  PARAM_PLAYER = "player",
  -- PARAM_REPUTATION = "reputation",
  -- PARAM_REPUTATION_NAME = "name",
  -- PARAM_REPUTATION_LEVEL = "level",
  PARAM_RECIPIENT = "recipient",
  PARAM_REWARDCHOICE = "choose",
  PARAM_REWARDITEM = "rewarditem",
  PARAM_REWARDMONEY = "rewardmoney",
  PARAM_SAMETARGET = "sametarget",
  PARAM_SPELL = "spell",
  PARAM_SPELLTARGET = "spelltarget",
  PARAM_SPELLTARGETCLASS = "spelltargetclass",
  PARAM_SPELLTARGETFACTION = "spelltargetfaction",
  PARAM_SPELLTARGETGUILD = "spelltargetguild",
  PARAM_SPELLTARGETLEVEL = "spelltargetlevel",
  PARAM_SUBZONE = "subzone",
  PARAM_TARGET = "target",
  PARAM_TARGETCLASS = "targetclass",
  PARAM_TARGETFACTION = "targetfaction",
  PARAM_TARGETGUILD = "targetguild",
  PARAM_TARGETLEVEL = "targetlevel",
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
  [t.CMD_CHAIN] = {
    type = "table",
    properties = {
      ["name"] = { type = "string" },
      ["order"] = { type = "number" },
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