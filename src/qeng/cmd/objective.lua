local _, addon = ...
addon:traceFile("cmd/objective.lua")
local compiler, tokens = addon.QuestScriptCompiler, addon.QuestScript.tokens

compiler:AddScript(tokens.CMD_OBJ, tokens.METHOD_PARSE, function(quest, args)
  local num = 0
  for i, obj in ipairs(args) do
    num = i
    local ok, objective = pcall(compiler.ParseObjective, compiler, obj)
    if not ok then
      error("Failed to parse objective #"..i..": "..objective)
    end

    if not quest.objectives then
      quest.objectives = {}
    end

    table.insert(quest.objectives, objective)
  end
  if num == 0 then
    error("No objectives specified")
  end
end)
