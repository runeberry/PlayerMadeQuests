local _, addon = ...

local parameter = addon.QuestEngine:NewParameter(addon.QuestScriptTokens.PARAM_SAMETARGET)
parameter:AllowType("boolean")