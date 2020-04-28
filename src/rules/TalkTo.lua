local _, addon = ...
addon:traceFile("TalkTo.lua")

local rule = addon.QuestEngine:CreateRule("TalkTo")
rule.displayText = "Talk to %1 %p/%g"

function rule:CheckObjective(obj)
  local unitName = GetUnitName("target")

  if obj.args[1] ~= unitName then
    -- The targeted unit's name does not match the objective's unit name
    return false
  end

  if obj.goal == 1 then
    -- Only one unit to talk to, so the objective is complete
    return true
  else
    -- If the objective is to talk to multiples of the same NPC (i.e. 3 guards),
    -- make sure they're different by guid
    local guid = UnitGUID("target")

    if obj.history == nil then
      -- First one, log this result and return true
      obj.history = { guid }
      return true
    end

    for _, g in pairs(obj.history) do
      if g == guid then
        -- Already talked to this NPC, don't count it
        return false
      end
    end

    -- Otherwise, log this guid and progress the objective
    table.insert(obj.history, guid)
    return true
  end
end

-- Publish the TalkTo event anytime the player targets a friendly unit
-- that activates one of the registered events below
local function publishEvent()
  if UnitExists("target") and UnitIsFriend("player", "target") then
    addon.RuleEvents:Publish(rule.name)
  end
end

addon:onload(function()
  addon.GameEvents:Subscribe("AUCTION_HOUSE_SHOW", publishEvent)
  addon.GameEvents:Subscribe("BANKFRAME_OPENED", publishEvent)
  addon.GameEvents:Subscribe("GOSSIP_SHOW", publishEvent)
  addon.GameEvents:Subscribe("MERCHANT_SHOW", publishEvent)
  addon.GameEvents:Subscribe("PET_STABLE_SHOW", publishEvent)
  addon.GameEvents:Subscribe("QUEST_DETAIL", publishEvent)
end)