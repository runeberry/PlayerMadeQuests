local addon = require("spec/addon-builder"):Build()
local game = require("spec/game-env")
local QuestDemos = addon.QuestDemos
local DebugQuests = addon.DebugQuests

addon:Init()
addon:Advance()

describe("QuestDemos", function()
  local demos = QuestDemos:FindAll()
  for _, demo in ipairs(demos) do
    it(string.format("can compile demo quest %s (%s)", demo.demoName, demo.demoId), function()
      local ok, quest = QuestDemos:CompileDemo(demo.demoId)
      assert(ok, quest)
    end)
  end
end)

describe("DebugQuests", function()
  setup(function()
    game:SetSpellName(addon, 1, "Fire Blast")
    game:SetSpellName(addon, 2, "Frostbolt")
    game:SetSpellName(addon, 3, "Arcane Intellect")
    game:SetSpellName(addon, 4, "Frost Armor")
    game:SetSpellName(addon, 5, "Fireball")
  end)
  local dqs = DebugQuests:FindAll()
  for _, dq in ipairs(dqs) do
    it(string.format("can compile debug quest %s (%s)", dq.name, dq.questId), function()
      local ok, quest = DebugQuests:CompileDebugQuest(dq.questId)
      assert(ok, quest)
    end)
  end
end)