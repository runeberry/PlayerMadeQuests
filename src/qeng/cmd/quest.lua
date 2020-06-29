local _, addon = ...
addon:traceFile("cmd/quest.lua")
local compiler, tokens = addon.QuestScriptCompiler, addon.QuestScript.tokens

compiler:AddScript(tokens.CMD_QUEST, tokens.METHOD_PARSE, function(quest, args)
  if args.name then
    quest.name = args.name
  end

  if args.description then
    quest.description = args.description
  end
end)