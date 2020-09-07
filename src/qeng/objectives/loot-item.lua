local _, addon = ...
local tokens = addon.QuestScriptTokens

local objective = addon.QuestEngine:NewObjective("loot-item")

objective:AddShorthandForm(tokens.PARAM_GOAL, tokens.PARAM_ITEM)

objective:AddParameter(tokens.PARAM_GOAL)
objective:AddParameter(tokens.PARAM_TEXT, {
  defaultValue = {
    log = "%i %p/%g",
    progress = "%i %p/%g",
    quest = "Loot [%g2|a] %i[%xyz: while in %xyz][%a: while having %a][%e: while wearing %e]",
    full = "Loot [%g2|a] %i[%xyz: while in %xyrz][%a: while having %a][%e: while wearing %e]",
  }
})

objective:AddCondition(tokens.PARAM_ITEM, { required = true })
objective:AddCondition(tokens.PARAM_AURA)
objective:AddCondition(tokens.PARAM_EQUIP)
objective:AddCondition(tokens.PARAM_ZONE)
objective:AddCondition(tokens.PARAM_SUBZONE)
objective:AddCondition(tokens.PARAM_COORDS)

local lootDelta -- Capture the name

objective:AddAppEvent("PlayerLootedItem", function(delta)
  lootDelta = delta
  return true
end)

function objective:AfterEvaluate(result, obj)
  if not result then return end

  if not lootDelta then
    self.logger:Fail("Unable to determine item(s) looted")
    return false
  end

  local items = obj.conditions[tokens.PARAM_ITEM]

  -- Get the total quantity of all items for this objective
  local totalQtyLooted = 0
  for item in pairs(items) do
    local qtyItemLooted = lootDelta[item] or 0
    totalQtyLooted = totalQtyLooted + qtyItemLooted
  end

  if totalQtyLooted > 0 then
    self.logger:Pass("Item loot progress (+%i)", totalQtyLooted)
    return totalQtyLooted
  else
    -- Don't return negative progress for this objective
    -- Looting gains cannot be undone - possibly reconsider for future?
    self.logger:Fail("Item loot did not progress (%i)", totalQtyLooted)
    return 0
  end
end