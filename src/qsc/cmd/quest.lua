local _, addon = ...
addon:traceFile("cmd/quest.lua")

local cmd = addon.QuestScript:NewCommand("quest", "q")

--function cmd:Parse(quest, args)
cmd.Parse = function(cmd, quest, args)
  local name = args:GetValue("name", "n", 2)

  addon:info("quest name =", name)
  if name then
    quest.name = name
  end

  local description = args:GetValue("description", "desc", "d", 3)
  if description then
    quest.description = description
  end
end