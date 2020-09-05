local _, addon = ...
local tokens = addon.QuestScriptTokens

local function setup(checkpoint)
  checkpoint:AddParameter(tokens.PARAM_TEXT, {
    defaultValue = {
      log = "Go to %t[%sz:[%t: at] %sz|[%z:[%t: in] %z]]",
      quest = "Go to [%t ][%atin ]%xyz[%a: while having %a]",
      full = "Go to [%t ][%atin ]%xyrz[%a: while having %a]"
    },
  })

  checkpoint:AddCondition(tokens.PARAM_AURA)
  checkpoint:AddCondition(tokens.PARAM_TARGET)
  checkpoint:AddCondition(tokens.PARAM_ZONE)
  checkpoint:AddCondition(tokens.PARAM_SUBZONE)
  checkpoint:AddCondition(tokens.PARAM_COORDS)
end

local startCheckpoint = addon.QuestEngine:NewCheckpoint("start")
setup(startCheckpoint)

local completeCheckpoint = addon.QuestEngine:NewCheckpoint("complete")
setup(completeCheckpoint)