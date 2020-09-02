local _, addon = ...
local tokens = addon.QuestScriptTokens

--- Required and recommended should be almost identical, so they are
--- both defined in this file
local function setup(checkpoint)
  checkpoint:AddCondition(tokens.PARAM_CLASS)
  checkpoint:AddCondition(tokens.PARAM_FACTION)
  checkpoint:AddCondition(tokens.PARAM_LEVEL)
end

local required = addon.QuestEngine:NewCheckpoint("required")
setup(required)

local recommended = addon.QuestEngine:NewCheckpoint("recommended")
setup(recommended)