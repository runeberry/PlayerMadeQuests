local _, addon = ...
local loader = addon.QuestScriptLoader
local compiler = addon.QuestScriptCompiler
local tokens = addon.QuestScriptTokens

loader:AddScript(tokens.CMD_OBJ, tokens.METHOD_PARSE, function(quest, args)
  local num = 0
  for i, obj in ipairs(args) do
    num = i
    local ok, objective = pcall(compiler.ParseObjective, compiler, obj)
    if not ok then
      error("Failed to parse objective #"..i..": "..objective)
    end

    objective.questId = quest.questId

    table.insert(quest.objectives, objective)
  end
  if num == 0 then
    error("No objectives specified")
  end
end)
