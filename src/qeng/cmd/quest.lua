local _, addon = ...
addon:traceFile("cmd/quest.lua")
local compiler, tokens = addon.QuestScriptCompiler, addon.QuestScript.tokens

compiler:AddScript(tokens.CMD_QUEST, tokens.METHOD_PARSE, function(quest, args)
  local name = compiler:GetArgsValue(args, "name", "n", 2)
  if name then
    quest.name = name
  end

  local description = compiler:GetArgsValue(args, "description", "desc", "d", 3)
  if description then
    quest.description = description
  end
end)