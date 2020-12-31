local _, addon = ...
local tokens = addon.QuestScriptTokens

local function setup(checkpoint)
  checkpoint:AddParameter(tokens.PARAM_TEXT, {
    defaultValue = {
      log = "[%t:Target %t|[%z2:Go to]][%sz:[%t: at] %sz|[%z:[%t: in] %z]].",
      quest = "[%t:Target %t[ %atin]|[%z2:Go to]][ %xyz][%a: while having %a].",
      full = "[%t:Target %t[ %atin]|[%z2:Go to]][ %xyrz][%a: while having %a]."
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