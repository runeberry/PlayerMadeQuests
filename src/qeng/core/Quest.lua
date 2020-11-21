local _, addon = ...
local tokens = addon.QuestScriptTokens
local assertf, errorf = addon.assertf, addon.errorf

local checkpoints = addon.QuestEngine.definitions.checkpoints
local objectives = addon.QuestEngine.definitions.objectives

function addon:ParseQuest(questRaw)
  local quest = {
    objectives = {}
  }

  local questSection = questRaw[tokens.CMD_QUEST]
  if questSection then
    quest.name = questSection[tokens.PARAM_NAME]

    local description, completion = questSection[tokens.PARAM_DESCRIPTION], questSection[tokens.PARAM_COMPLETION]

    if description then
      quest.description = description
    end
    if completion then
      quest.completion = completion
    end
  end

  if questRaw[tokens.CMD_OBJ] then
    local num = 0
    for i, objRaw in ipairs(questRaw[tokens.CMD_OBJ]) do
      num = i
      -- Objectives may be in a special shorthand form, so this will find the
      -- "name" and "value" of the objective from whatever form it's in
      local objName, objArgs = addon:ParseShorthand(objRaw)
      local objective = objectives[objName]
      assertf(objective, "'%s' is not a known objective name", tostring(objName))

      local obj = objective:Parse(objArgs)
      table.insert(quest.objectives, obj)
    end
    if num == 0 then
      -- todo: allow quests with no objectives
      -- need to make updates to tracking and statuses for quests that would be
      -- considered "finished" as soon as they are accepted
      error("No objectives specified")
    end
  end

  if questRaw[tokens.CMD_START] then
    quest.start = checkpoints["start"]:Parse(questRaw[tokens.CMD_START])
  end
  if questRaw[tokens.CMD_COMPLETE] then
    quest.complete = checkpoints["complete"]:Parse(questRaw[tokens.CMD_COMPLETE])
  end
  if questRaw[tokens.CMD_REQ] then
    quest.required = checkpoints["required"]:Parse(questRaw[tokens.CMD_REQ])
  end
  if questRaw[tokens.CMD_REC] then
    quest.recommended = checkpoints["recommended"]:Parse(questRaw[tokens.CMD_REC])
  end

  return quest
end