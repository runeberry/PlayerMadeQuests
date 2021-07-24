local builder = require("spec/addon-builder")
local events = require("spec/events")
local game = require("spec/game-env")
local addon = builder:Build()
local compiler = addon.QuestScriptCompiler
local QuestLog, QuestStatus = addon.QuestLog, addon.QuestStatus

local questStub = [[
  quest:
    name: Test Quest
  objectives:
    - %s
]]

--- Creates a basic quest with the one objective provided
--- and begins tracking that quest
local function startQuest(script)
  local quest = compiler:Compile(string.format(questStub, script))
  addon:AcceptQuest(quest)
  addon:Advance()
  return quest
end

--- Fires the QuestEvent associated with the first objective on the quest
--- and asserts that that objective is updated as a result
--- (in other words, asserts that all conditions were met)
local function assertObjectiveDoesUpdate(quest, appEventSpy)
  local objective = quest.objectives[1]
  assert.is_not_nil(objective, "Quest has no objectives")
  appEventSpy = appEventSpy or events:SpyOnEvents(addon.AppEvents)
  -- addon:ForceLogs(function()
    addon.QuestEvents:Publish(objective.name)
    addon:Advance()
  -- end)
  local payload = appEventSpy:GetPublishPayload("ObjectiveUpdated", 1)
  assert.is_not_nil(payload, "ObjectiveUpdated published no payload")
  assert.same(objective.id, payload.id, "Id on payload did not match objective")
  assert.is_true(payload.progress > 0, "Quest objective should have progressed")
end

--- Fires the QuestEvent associated with the first objective on the quest
--- and asserts that that objective is NOT updated as a result
--- (in other words, asserts that some condition was NOT met)
local function assertObjectiveDoesNotUpdate(quest, appEventSpy)
  local objective = quest.objectives[1]
  assert.is_not_nil(objective, "Quest has no objectives")
  appEventSpy = appEventSpy or events:SpyOnEvents(addon.AppEvents)
  -- addon:ForceLogs(function()
    addon.QuestEvents:Publish(objective.name)
    addon:Advance()
  -- end)
  appEventSpy:AssertNotPublished("ObjectiveUpdated")
end

describe("Condition", function()
  setup(function()
    addon:Init()
    addon:Advance()
  end)
  before_each(function()
    game:ResetEnv(addon)
    QuestLog:DeleteAll()
    addon:Advance()
  end)
  ----------
  -- aura --
  ----------
  describe("aura", function()
    describe("when player aura matches quest aura", function()
      it("then the condition passes", function()
        local quest = startQuest("gain-aura 'Blessing of Might'")
        game:AddPlayerAura(addon, { name = "Blessing of Might", spellId = 1234 })
        assertObjectiveDoesUpdate(quest)
      end)
    end)
    describe("when player aura matches one of multiple quest auras", function()
      it("then the condition passes", function()
        local quest = startQuest("gain-aura: { aura: [ Blessing of Might, 'Power Word: Fortitude' ] }")
        game:AddPlayerAura(addon, { name = "Blessing of Might", spellId = 1234 })
        assertObjectiveDoesUpdate(quest)
      end)
    end)
    describe("when player auras do not match quest aura", function()
      it("then the condition fails", function()
        local quest = startQuest("gain-aura: { aura: 'Power Word: Fortitude' }")
        game:AddPlayerAura(addon, { name = "Blessing of Might", spellId = 1234 })
        game:AddPlayerAura(addon, { name = "Underwater Breathing", spellId = 1235 })
        assertObjectiveDoesNotUpdate(quest)
      end)
    end)
    describe("when player auras do not match any of multiple quest auras", function()
      it("then the condition fails", function()
        local quest = startQuest("gain-aura: { aura: [ 'Power Word: Fortitude', Mage Armor ] }")
        game:AddPlayerAura(addon, { name = "Blessing of Might", spellId = 1234 })
        game:AddPlayerAura(addon, { name = "Underwater Breathing", spellId = 1235 })
        assertObjectiveDoesNotUpdate(quest)
      end)
    end)
  end)
  -----------
  -- emote --
  -----------
  describe("emote", function()
    after_each(function()
      addon.LastEmoteMessage = nil
    end)
    describe("when player emote matches objective emote", function()
      it("then the condition passes", function()
        local quest = startQuest("use-emote glare")
        addon.LastEmoteMessage = "You glare angrily."
        assertObjectiveDoesUpdate(quest)
      end)
    end)
    describe("when player emote matches one of multiple objective emotes", function()
      it("then the condition passes", function()
        local quest = startQuest("use-emote: { emote: [ glare, roar ] }")
        addon.LastEmoteMessage = "You glare angrily."
        assertObjectiveDoesUpdate(quest)
      end)
    end)
    describe("when player emote does not match objective emote", function()
      it("then the condition fails", function()
        local quest = startQuest("use-emote roar")
        addon.LastEmoteMessage = "You glare angrily."
        assertObjectiveDoesNotUpdate(quest)
      end)
    end)
    describe("when player emote does not match any of multiple objective emotes", function()
      it("then the condition fails", function()
        local quest = startQuest("use-emote: { emote: [ roar, laugh ] }")
        addon.LastEmoteMessage = "You glare angrily."
        assertObjectiveDoesNotUpdate(quest)
      end)
    end)
  end)
  -----------
  -- equip --
  -----------
  describe("equip", function()
    describe("when player has the item equipped", function()
      it("then the condition passes", function()
        local quest = startQuest("equip-item 'Stinky Hat'")
        game:AddPlayerEquipment(addon, { name = "Stinky Hat" })
        assertObjectiveDoesUpdate(quest)
      end)
    end)
    describe("when player has one of multiple items equipped", function()
      it("then the condition passes", function()
        local quest = startQuest("equip-item: { equip: [ Stinky Hat, Pretty Hat ] }")
        addon.LastEmoteMessage = "You glare angrily."
        game:AddPlayerEquipment(addon, { name = "Stinky Hat" })
        assertObjectiveDoesUpdate(quest)
      end)
    end)
    describe("when player does not have the item equipped", function()
      it("then the condition fails", function()
        local quest = startQuest("equip-item 'Pretty Hat'")
        game:AddPlayerEquipment(addon, { name = "Stinky Hat" })
        assertObjectiveDoesNotUpdate(quest)
      end)
    end)
    describe("when player does not have any of multiple items equipped", function()
      it("then the condition fails", function()
        local quest = startQuest("equip-item: { equip: [ Pretty Hat, Exquisite Hat ] }")
        game:AddPlayerEquipment(addon, { name = "Stinky Hat" })
        assertObjectiveDoesNotUpdate(quest)
      end)
    end)
  end)
  ----------
  -- item --
  ----------
  describe("item", function()
    -- todo: I don't have an item-based objective yet, using emote for now
    after_each(function()
      addon.LastEmoteMessage = nil
    end)
    describe("when player has the item", function()
      it("then the condition passes", function()
        local quest = startQuest("use-emote: { emote: glare, item: Hearthstone }")
        addon.LastEmoteMessage = "You glare angrily."
        game:AddPlayerItem(addon, { name = "Hearthstone" })
        assertObjectiveDoesUpdate(quest)
      end)
    end)
    describe("when player has one of multiple items", function()
      it("then the condition passes", function()
        local quest = startQuest("use-emote: { emote: glare, item: [ Hearthstone, Minor Healing Potion ] }")
        addon.LastEmoteMessage = "You glare angrily."
        game:AddPlayerItem(addon, { name = "Hearthstone" })
        assertObjectiveDoesUpdate(quest)
      end)
    end)
    describe("when player does not have the item", function()
      it("then the condition fails", function()
        local quest = startQuest("use-emote: { emote: glare, item: Minor Healing Potion }")
        addon.LastEmoteMessage = "You glare angrily."
        game:AddPlayerItem(addon, { name = "Hearthstone" })
        assertObjectiveDoesNotUpdate(quest)
      end)
    end)
    describe("when player does not have any of multiple items", function()
      it("then the condition fails", function()
        local quest = startQuest("use-emote: { emote: glare, item: [ Minor Healing Potion, Minor Mana Potion ] }")
        game:AddPlayerItem(addon, { name = "Hearthstone" })
        assertObjectiveDoesNotUpdate(quest)
      end)
    end)
  end)
  ----------------
  -- killtarget --
  ----------------
  describe("killtarget", function()
    after_each(function()
      addon.LastPartyKill = nil
    end)
    describe("when player kills the target", function()
      it("then the condition passes", function()
        local quest = startQuest("kill 'Stonetusk Boar'")
        addon.LastPartyKill = { destName = 'Stonetusk Boar', destGuid = 'Creature-0-4389-0-2-113-00001E92C2' }
        assertObjectiveDoesUpdate(quest)
      end)
    end)
    describe("when player kills one of multiple targets", function()
      it("then the condition passes", function()
        local quest = startQuest("kill: { target: [ Stonetusk Boar, Chicken ] }")
        addon.LastPartyKill = { destName = 'Stonetusk Boar', destGuid = 'Creature-0-4389-0-2-113-00001E92C2' }
        assertObjectiveDoesUpdate(quest)
      end)
    end)
    describe("when player kills a different target", function()
      it("then the condition fails", function()
        local quest = startQuest("kill Ragnaros")
        addon.LastPartyKill = { destName = 'Stonetusk Boar', destGuid = 'Creature-0-4389-0-2-113-00001E92C2' }
        assertObjectiveDoesNotUpdate(quest)
      end)
    end)
    describe("when player kills none of multiple targets", function()
      it("then the condition fails", function()
        local quest = startQuest("kill: { target: [ Ragnaros, Onyxia ] }")
        addon.LastPartyKill = { destName = 'Stonetusk Boar', destGuid = 'Creature-0-4389-0-2-113-00001E92C2' }
        assertObjectiveDoesNotUpdate(quest)
      end)
    end)
  end)
  --------------------------------------------
  -- message, recipient, language & channel --
  --------------------------------------------
  describe("message", function()
    after_each(function()
      addon.LastChatChannel = nil
      addon.LastChatMessage = nil
      addon.LastChatLanguage = nil
      addon.LastChatRecipient = nil
    end)
    describe("when the player says a message", function()
      local testCases = {
        { pattern = "something", chat = "This message contains SOMEthing interesting!", pass = true },
        { pattern = "^exact MATCH$", chat = "EXACT match", pass = true },
        { pattern = "^exact MATCH$", chat = "EXACT match!", pass = false },
        { pattern = "^start with", chat = "start with the pattern", pass = true },
        { pattern = "^start with", chat = "this doesn't start with the pattern", pass = false },
        { pattern = "end with$", chat = "the pattern it should END with", pass = true },
        { pattern = "end with$", chat = "this doesn't end with the pattern", pass = false },
        { pattern = "wildcard %w- words", chat = "this has some wildcard whatever words", pass = true },
        { pattern = "wildcard %w- words", chat = "this has several wildcard whatever you can think of words", pass = false },
        { pattern = "wildcard %w- words", chat = "doesn't have any wildcard words", pass = false },
        { pattern = "wildcard %d- numbers", chat = "have some wildcard 70891 numbers", pass = true },
        { pattern = "wildcard %d- numbers", chat = "has no wildcard numbers", pass = false },
      }

      for _, tc in ipairs(testCases) do
        if tc.pass then
          it("it matches the pattern", function()
            local quest = startQuest(string.format("say \"%s\"", tc.pattern))
            addon.LastChatMessage = tc.chat
            assertObjectiveDoesUpdate(quest)
          end)
        else
          it("it does not match the pattern", function()
            local quest = startQuest(string.format("say \"%s\"", tc.pattern))
            addon.LastChatMessage = tc.chat
            assertObjectiveDoesNotUpdate(quest)
          end)
        end
      end

      describe("and", function()
        local quest
        before_each(function()
          addon.LastChatMessage = "hello"
        end)
        describe("a channel is specified", function()
          before_each(function()
            quest = startQuest("say: { message: hello, channel: yell }")
          end)
          it("will pass on a matching channel", function()
            addon.LastChatChannel = "yell"
            assertObjectiveDoesUpdate(quest)
          end)
          it("will not pass on a different channel", function()
            addon.LastChatChannel = "guild"
            assertObjectiveDoesNotUpdate(quest)
          end)
        end)
        describe("multiple channels are specified", function()
          before_each(function()
            quest = startQuest("say: { message: hello, channel: [ say, yell ] }")
          end)
          it("will pass on a matching channel", function()
            addon.LastChatChannel = "say"
            assertObjectiveDoesUpdate(quest)
          end)
          it("will not pass on a different channel", function()
            addon.LastChatChannel = "whisper"
            assertObjectiveDoesNotUpdate(quest)
          end)
        end)
        describe("a language is specified", function()
          before_each(function()
            quest = startQuest("say: { message: hello, language: Dwarvish }")
          end)
          it("will pass with a matching language", function()
            addon.LastChatLanguage = "Dwarvish"
            assertObjectiveDoesUpdate(quest)
          end)
          it("will not pass with a different language", function()
            addon.LastChatLanguage = "Gutterspeak"
            assertObjectiveDoesNotUpdate(quest)
          end)
          it("will not pass without a language", function()
            addon.LastChatLanguage = nil
            assertObjectiveDoesNotUpdate(quest)
          end)
        end)
        describe("multiple languages are specified", function()
          before_each(function()
            quest = startQuest("say: { message: hello, language: [ Dwarvish, Gnomish ] }")
          end)
          it("will pass with a matching language", function()
            addon.LastChatLanguage = "Gnomish"
            assertObjectiveDoesUpdate(quest)
          end)
          it("will not pass with a different language", function()
            addon.LastChatLanguage = "Gutterspeak"
            assertObjectiveDoesNotUpdate(quest)
          end)
          it("will not pass without a language", function()
            addon.LastChatLanguage = nil
            assertObjectiveDoesNotUpdate(quest)
          end)
        end)
        describe("a recipient is specified", function()
          before_each(function()
            quest = startQuest("say: { message: hello, recipient: Sans }")
          end)
          it("will pass with a matching recipient", function()
            addon.LastChatRecipient = "Sans"
            assertObjectiveDoesUpdate(quest)
          end)
          it("will not pass with a different recipient", function()
            addon.LastChatRecipient = "Undyne"
            assertObjectiveDoesNotUpdate(quest)
          end)
          it("will not pass without a recipient", function()
            addon.LastChatRecipient = nil
            assertObjectiveDoesNotUpdate(quest)
          end)
        end)
        describe("multiple recipients are specified", function()
          before_each(function()
            quest = startQuest("say: { message: hello, recipient: [ Sans, Papyrus ] }")
          end)
          it("will pass with a matching recipient", function()
            addon.LastChatRecipient = "Papyrus"
            assertObjectiveDoesUpdate(quest)
          end)
          it("will not pass with a different recipient", function()
            addon.LastChatRecipient = "Alphys"
            assertObjectiveDoesNotUpdate(quest)
          end)
          it("will not pass without a recipient", function()
            addon.LastChatRecipient = nil
            assertObjectiveDoesNotUpdate(quest)
          end)
        end)
      end)
    end)
  end)
  ------------
  -- target --
  ------------
  describe("target", function()
    describe("when the player has no target", function()
      it("then the condition fails", function()
        local quest = startQuest("talk-to 'Stormwind Guard'")
        assertObjectiveDoesNotUpdate(quest)
      end)
    end)
    describe("when player has the correct target", function()
      it("then the condition passes", function()
        local quest = startQuest("talk-to 'Stormwind Guard'")
        game:SetPlayerTarget(addon, { name = "Stormwind Guard" })
        assertObjectiveDoesUpdate(quest)
      end)
    end)
    describe("when player has one of multiple targets", function()
      it("then the condition passes", function()
        local quest = startQuest("talk-to: { target: [ 'Stormwind Guard', Erma ] }")
        game:SetPlayerTarget(addon, { name = "Stormwind Guard" })
        assertObjectiveDoesUpdate(quest)
      end)
    end)
    describe("when player has a different target", function()
      it("then the condition fails", function()
        local quest = startQuest("talk-to 'Marshal Dughan'")
        game:SetPlayerTarget(addon, { name = "Stormwind Guard" })
        assertObjectiveDoesNotUpdate(quest)
      end)
    end)
    describe("when player does not have any of multiple targets", function()
      it("then the condition fails", function()
        local quest = startQuest("talk-to: { target: [ 'Marshal Dughan', Erma ] }")
        game:SetPlayerTarget(addon, { name = "Stormwind Guard" })
        assertObjectiveDoesNotUpdate(quest)
      end)
    end)
    describe("when player targets different guids", function()
      it("then the condition passes both times", function()
        local quest = startQuest("talk-to 2 'Stormwind Guard'")
        game:SetPlayerTarget(addon, { name = "Stormwind Guard", guid = "Creature-0-4389-0-2-1423-00001CE9A1"})
        assertObjectiveDoesUpdate(quest)
        game:ResetEnv(addon)
        game:SetPlayerTarget(addon, { name = "Stormwind Guard", guid = "Creature-0-4389-0-2-1423-0000996A91"})
        assertObjectiveDoesUpdate(quest)
      end)
    end)
    describe("when player targets a duplicate guid", function()
      it("then the condition fails the second time", function()
        local quest = startQuest("talk-to 2 'Stormwind Guard'")
        game:SetPlayerTarget(addon, { name = "Stormwind Guard", guid = "Creature-0-4389-0-2-1423-00001CE9A1"})
        assertObjectiveDoesUpdate(quest)
        game:ResetEnv(addon)
        game:SetPlayerTarget(addon, { name = "Stormwind Guard", guid = "Creature-0-4389-0-2-1423-00001CE9A1"})
        assertObjectiveDoesNotUpdate(quest)
      end)
      it("then the condition will pass the second time if it's a player (for some objectives)", function()
        local quest = startQuest("use-emote glare 5 Questborther")
        game:SetPlayerTarget(addon, { name = "Questborther", guid = "Player-4389-00BCF8B6"})
        addon.LastEmoteMessage = "You glare angrily at Questborther."
        assertObjectiveDoesUpdate(quest)
        game:ResetEnv(addon)
        game:SetPlayerTarget(addon, { name = "Questborther", guid = "Player-4389-00BCF8B6"})
        assertObjectiveDoesUpdate(quest)
      end)
    end)
  end)
  -------------------------------
  -- zone, subzone, and coords --
  -------------------------------
  describe("zone, subzone, and coords", function()
    describe("player is in matching zone", function()
      it("then the condition passes", function()
        local quest = startQuest("explore Durotar")
        game:SetPlayerLocation(addon, { zone = "Durotar" })
        assertObjectiveDoesUpdate(quest)
      end)
    end)
    describe("player is in matching zone and subzone", function()
      it("then the condition passes", function()
        local quest = startQuest("explore: { zone: Durotar, subzone: Skull Rock }")
        game:SetPlayerLocation(addon, { zone = "Durotar", subzone = "Skull Rock" })
        assertObjectiveDoesUpdate(quest)
      end)
    end)
    describe("player is in matching zone and coords", function()
      it("then the condition passes", function()
        local quest = startQuest("explore: { zone: Durotar, coords: '38,22' }")
        game:SetPlayerLocation(addon, { zone = "Durotar", x = 38, y = 22 })
        assertObjectiveDoesUpdate(quest)
      end)
    end)
    describe("player is in matching subzone and coords", function()
      it("then the condition passes", function()
        local quest = startQuest("explore: { subzone: Skull Rock, coords: '38.1,22.4' }")
        -- Within range of the default radius of 0.5 coordinate units
        game:SetPlayerLocation(addon, { subzone = "Skull Rock", x = 38.2, y = 22.3 })
        assertObjectiveDoesUpdate(quest)
      end)
    end)
    describe("player is in matching zone, subzone, and coords", function()
      it("then the condition passes", function()
        local quest = startQuest("explore: { zone: Durotar, subzone: Skull Rock, coords: '38.12, 22.34' }")
        -- Within range of the default radius of 0.5 coordinate units
        game:SetPlayerLocation(addon, { zone = "Durotar", subzone = "Skull Rock", x = 37.94, y = 21.98 })
        assertObjectiveDoesUpdate(quest)
      end)
    end)
    describe("player is within custom radius of coords", function()
      it("then the condition passes", function()
        local quest = startQuest("explore: { zone: Durotar, coords: '38.12, 22.34, 5.0' }")
        game:SetPlayerLocation(addon, { zone = "Durotar", subzone = "Skull Rock", x = 36.01, y = 26.08 })
        assertObjectiveDoesUpdate(quest)
      end)
    end)
    describe("player is not in matching zone", function()
      it("then the condition fails", function()
        local quest = startQuest("explore Durotar")
        game:SetPlayerLocation(addon, { zone = "Elwynn Forest" })
        assertObjectiveDoesNotUpdate(quest)
      end)
    end)
    describe("player is not in matching subzone", function()
      it("then the condition fails", function()
        local quest = startQuest("explore: { subzone: Skull Rock }")
        game:SetPlayerLocation(addon, { subzone = "Goldshire" })
        assertObjectiveDoesNotUpdate(quest)
      end)
    end)
    describe("player is not in matching coords", function()
      it("then the condition fails", function()
        local quest = startQuest("explore: Durotar 38,22")
        game:SetPlayerLocation(addon, { zone = "Durotar", x = 12, y = 15 })
        assertObjectiveDoesNotUpdate(quest)
      end)
    end)
  end)
end)