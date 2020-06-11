local _, addon = ...
addon:traceFile("cmd/quest.lua")
local compiler, tokens = addon.QuestScriptCompiler, addon.QuestScript.tokens

compiler:AddScript(tokens.CMD_QUEST, tokens.METHOD_PARSE, function(quest, args)
  local name = args:GetValue(tokens.PARAM_NAME)
  if name then
    quest.name = name
  end

  local description = args:GetValue(tokens.PARAM_DESCRIPTION)
  if description then
    quest.description = description
  end
end)