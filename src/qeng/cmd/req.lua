local _, addon = ...
local loader = addon.QuestScriptLoader
local tokens = addon.QuestScriptTokens

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

loader:AddScript(tokens.CMD_REC, tokens.METHOD_PARSE, function(quest, args)
  quest.recommended = parseRecs(args)
end)

loader:AddScript(tokens.CMD_REQ, tokens.METHOD_PARSE, function(quest, args)
  quest.required = parseRecs(args)
end)

local function checkRecs(recs)
  local result = {
    pass = true,
    details = {},
  }

  if not recs then return result end

  if recs.class then
    local class = UnitClass("player")
    if class:lower() == recs.class:lower() then
      result.details.class = true
    else
      result.details.class = false
      result.pass = false
    end
  end

  if recs.faction then
    local faction = UnitFactionGroup("player")
    if faction:lower() == recs.faction:lower() then
      result.details.class = true
    else
      result.details.class = false
      result.pass = false
    end
  end

  if recs.level then
    local level = UnitLevel("player")
    if level >= recs.level then
      result.details.level = true
    else
      result.details.level = false
      result.pass = false
    end
  end

  return result
end

loader:AddScript(tokens.CMD_REC, tokens.METHOD_EVAL, function(quest)
  return checkRecs(quest.recommended)
end)

loader:AddScript(tokens.CMD_REQ, tokens.METHOD_EVAL, function(quest)
  return checkRecs(quest.required)
end)