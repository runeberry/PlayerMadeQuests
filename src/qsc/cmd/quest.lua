local _, addon = ...

local cmd = addon.QuestScript:NewCommand("quest", "q")

function cmd:Parse(quest, args)
  local name = args:GetValue("name", "n", 2)
  if name then
    quest.name = name
  end

  local description = args:GetValue("description", "desc", "d", 3)
  if description then
    quest.description = description
  end
end