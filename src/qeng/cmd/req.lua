local _, addon = ...
local compiler, tokens = addon.QuestScriptCompiler, addon.QuestScript.tokens

local UnitClass = addon.G.UnitClass
local UnitFactionGroup = addon.G.UnitFactionGroup
local UnitLevel = addon.G.UnitLevel

local function parseRecs(args)
  local recs = {
    class = args[tokens.PARAM_CLASS],
    faction = args[tokens.PARAM_FACTION],
    level = args[tokens.PARAM_LEVEL],
  }

  return recs
end

compiler:AddScript(tokens.CMD_REC, tokens.METHOD_PARSE, function(quest, args)
  quest.recommended = parseRecs(args)
end)

compiler:AddScript(tokens.CMD_REQ, tokens.METHOD_PARSE, function(quest, args)
  quest.required = parseRecs(args)
end)

local function checkRecs(recs)
  if recs.class then
    local class = UnitClass("player")
    if class:lower() ~= recs.class:lower() then
      return false
    end
  end

  if recs.faction then
    local faction = UnitFactionGroup("player")
    if faction:lower() ~= recs.faction:lower() then
      return false
    end
  end

  if recs.level then
    local level = UnitLevel("player")
    if level < recs.level then
      return false
    end
  end

  return true
end

compiler:AddScript(tokens.CMD_REC, tokens.METHOD_CHECK_COND, function(quest)
  return checkRecs(quest.recommended)
end)

compiler:AddScript(tokens.CMD_REQ, tokens.METHOD_CHECK_COND, function(quest)
  return checkRecs(quest.required)
end)