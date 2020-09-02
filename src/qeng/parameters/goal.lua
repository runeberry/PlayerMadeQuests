local _, addon = ...

local parameter = addon.QuestEngine:NewParameter(addon.QuestScriptTokens.PARAM_GOAL)
parameter:AllowType("number")
parameter:SetDefaultValue(1)

function parameter:OnValidate(rawValue, options)
  if rawValue < 0 then
    return false, string.format("'%s' must be greater than zero", self.name)
  end
  return true
end