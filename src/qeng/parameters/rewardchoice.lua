local _, addon = ...

local parameter = addon.QuestEngine:NewParameter(addon.QuestScriptTokens.PARAM_REWARDCHOICE)
parameter:AllowType("boolean")
parameter:SetDefaultValue(false)