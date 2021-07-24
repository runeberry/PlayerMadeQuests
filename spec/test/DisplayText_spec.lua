local addon = require("spec/addon-builder"):Build()
local game = require("spec/game-env")
local compiler = addon.QuestScriptCompiler

local objectiveScriptTemplate = [[
  quest:
    name: Objective displaytext parser test
  objectives:
    - ]]

local function getDisplayText(obj, scope)
  return addon:GetCheckpointDisplayText(obj, scope)
end

describe("DisplayText", function()
  setup(function()
    addon:Init()
    addon:Advance()

    game:SetSpellName(addon, 123, "Fire Blast")
  end)
  describe("objective displaytext parser", function()
    local testCases = {
      {
        objective = "use-emote dance Chicken",
        expected = {
          log = "/dance with Chicken",
          progress = "/dance with Chicken: 0/1",
          quest = "/dance with Chicken",
          full = "Use emote /dance on Chicken"
        }
      },
      {
        objective = "use-emote fart 5 'Stormwind Guard'",
        expected = {
          log = "/fart with Stormwind Guard 0/5",
          progress = "/fart with Stormwind Guard: 0/5",
          quest = "/fart with 5 Stormwind Guard",
          full = "Use emote /fart on 5 Stormwind Guard"
        }
      },
      {
        objective = "use-emote cry",
        expected = {
          log = "/cry",
          progress = "/cry: 0/1",
          quest = "/cry",
          full = "Use emote /cry"
        }
      },
      {
        objective = "use-emote flex 3",
        expected = {
          log = "/flex 0/3",
          progress = "/flex: 0/3",
          quest = "/flex 3 times",
          full = "Use emote /flex 3 times"
        }
      },
      {
        objective = "use-emote: { emote: dance, guild: Theramore Guard }",
        expected = {
          log = "/dance with <Theramore Guard> member",
          progress = "/dance with <Theramore Guard> member: 0/1",
          quest = "/dance with <Theramore Guard> member",
          full = "Use emote /dance on <Theramore Guard> member",
        }
      },
      {
        objective = "use-emote: { emote: dance, class: Druid }",
        expected = {
          log = "/dance with Druid",
          progress = "/dance with Druid: 0/1",
          quest = "/dance with Druid",
          full = "Use emote /dance on Druid",
        }
      },
      {
        objective = "use-emote: { emote: dance, level: 30 }",
        expected = {
          log = "/dance with Level 30+ foe",
          progress = "/dance with Level 30+ foe: 0/1",
          quest = "/dance with Level 30+ foe",
          full = "Use emote /dance on Level 30+ foe",
        }
      },
      {
        objective = "use-emote: { emote: dance, faction: Horde }",
        expected = {
          log = "/dance with Horde foe",
          progress = "/dance with Horde foe: 0/1",
          quest = "/dance with Horde foe",
          full = "Use emote /dance on Horde foe",
        }
      },
      {
        objective = "use-emote: { emote: dance, guild: Theramore Guard, class: Druid, level: 30, faction: Horde }",
        expected = {
          log = "/dance with Level 30+ Horde <Theramore Guard> Druid",
          progress = "/dance with Level 30+ Horde <Theramore Guard> Druid: 0/1",
          quest = "/dance with Level 30+ Horde <Theramore Guard> Druid",
          full = "Use emote /dance on Level 30+ Horde <Theramore Guard> Druid",
        }
      },
      {
        objective = "explore Durotar",
        expected = {
          log = "Go to Durotar",
          progress = "Durotar explored: 0/1",
          quest = "Explore Durotar",
          full = "Go to Durotar"
        }
      },
      {
        objective = "explore Westfall 25.2,38.4",
        expected = {
          log = "Go to (25.2, 38.4) in Westfall",
          progress = "(25.2, 38.4) in Westfall explored: 0/1",
          quest = "Explore (25.2, 38.4) in Westfall",
          full = "Go to (25.2, 38.4) in Westfall"
        }
      },
      {
        objective = "explore: { zone: Ironforge, subzone: The War Quarter }",
        expected = {
          log = "Go to The War Quarter",
          progress = "The War Quarter explored: 0/1",
          quest = "Explore The War Quarter in Ironforge",
          full = "Go to The War Quarter in Ironforge"
        }
      },
      {
        objective = "explore: { zone: Elwynn Forest, coords: '32, 20, 5' }",
        expected = {
          log = "Go to (32, 20) in Elwynn Forest",
          progress = "(32, 20) in Elwynn Forest explored: 0/1",
          quest = "Explore (32, 20) in Elwynn Forest",
          full = "Go to (32, 20) +/- 5 in Elwynn Forest"
        }
      },
      {
        objective = "explore: { zone: Elwynn Forest, subzone: Goldshire, coords: \"32,20,5\" }",
        expected = {
          log = "Go to (32, 20) in Goldshire",
          progress = "(32, 20) in Goldshire explored: 0/1",
          quest = "Explore (32, 20) in Goldshire in Elwynn Forest",
          full = "Go to (32, 20) +/- 5 in Goldshire in Elwynn Forest"
        }
      },
      {
        objective = "kill Ragnaros",
        expected = {
          log = "Ragnaros 0/1",
          progress = "Ragnaros slain: 0/1",
          quest = "Kill Ragnaros",
          full = "Kill Ragnaros"
        }
      },
      {
        objective = "kill 15 'Mangy Wolf'",
        expected = {
          log = "Mangy Wolf 0/15",
          progress = "Mangy Wolf slain: 0/15",
          quest = "Kill 15 Mangy Wolf",
          full = "Kill 15 Mangy Wolf"
        }
      },
      {
        objective = "kill: { guild: Theramore Guard }",
        expected = {
          log = "<Theramore Guard> member 0/1",
          progress = "<Theramore Guard> member slain: 0/1",
          quest = "Kill <Theramore Guard> member",
          full = "Kill <Theramore Guard> member",
        }
      },
      {
        objective = "kill: { class: Druid }",
        expected = {
          log = "Druid 0/1",
          progress = "Druid slain: 0/1",
          quest = "Kill Druid",
          full = "Kill Druid",
        }
      },
      {
        objective = "kill: { level: 30 }",
        expected = {
          log = "Level 30+ foe 0/1",
          progress = "Level 30+ foe slain: 0/1",
          quest = "Kill Level 30+ foe",
          full = "Kill Level 30+ foe",
        }
      },
      {
        objective = "kill: { faction: Horde }",
        expected = {
          log = "Horde foe 0/1",
          progress = "Horde foe slain: 0/1",
          quest = "Kill Horde foe",
          full = "Kill Horde foe",
        }
      },
      {
        objective = "kill: { guild: Theramore Guard, class: Druid, level: 30, faction: Horde }",
        expected = {
          log = "Level 30+ Horde <Theramore Guard> Druid 0/1",
          progress = "Level 30+ Horde <Theramore Guard> Druid slain: 0/1",
          quest = "Kill Level 30+ Horde <Theramore Guard> Druid",
          full = "Kill Level 30+ Horde <Theramore Guard> Druid",
        }
      },
      {
        objective = "talk-to Rexxar",
        expected = {
          log = "Talk to Rexxar",
          progress = "Talk to Rexxar: 0/1",
          quest = "Talk to Rexxar",
          full = "Talk to Rexxar"
        }
      },
      {
        objective = "talk-to 2 'Stormwind Guard'",
        expected = {
          log = "Talk to Stormwind Guard 0/2",
          progress = "Talk to Stormwind Guard: 0/2",
          quest = "Talk to 2 Stormwind Guard",
          full = "Talk to 2 Stormwind Guard"
        }
      },
      {
        objective = "cast-spell 'Fire Blast'",
        expected = {
          log = "Fire Blast 0/1",
          progress = "Cast Fire Blast: 0/1",
          quest = "Cast Fire Blast",
          full = "Cast Fire Blast"
        }
      },
      {
        objective = "cast-spell 5 123",
        expected = {
          log = "Fire Blast 0/5",
          progress = "Cast Fire Blast: 0/5",
          quest = "Cast Fire Blast 5 times",
          full = "Cast Fire Blast 5 times"
        }
      },
      {
        -- The goal of 1 here is necessary so it's not ambiguous w/ spellId
        objective = "cast-spell 1 123 'Stonetusk Boar'",
        expected = {
          log = "Fire Blast on Stonetusk Boar 0/1",
          progress = "Cast Fire Blast on Stonetusk Boar: 0/1",
          quest = "Cast Fire Blast on Stonetusk Boar",
          full = "Cast Fire Blast on Stonetusk Boar"
        }
      },
      {
        objective = "cast-spell 6 'Fire Blast' Rexxar",
        expected = {
          log = "Fire Blast on Rexxar 0/6",
          progress = "Cast Fire Blast on Rexxar: 0/6",
          quest = "Cast Fire Blast on 6 different Rexxar",
          full = "Cast Fire Blast on 6 different Rexxar"
        }
      },
      {
        objective = "cast-spell: { spell: 'Fire Blast', goal : 6, target: Rexxar, sametarget: true }",
        expected = {
          log = "Fire Blast on Rexxar 0/6",
          progress = "Cast Fire Blast on Rexxar: 0/6",
          quest = "Cast Fire Blast on Rexxar 6 times",
          full = "Cast Fire Blast on Rexxar 6 times"
        }
      },
      {
        -- Sametarget should have no effect if goal == 1
        objective = "cast-spell: { spell: 'Fire Blast', target: Stonetusk Boar, sametarget: true }",
        expected = {
          log = "Fire Blast on Stonetusk Boar 0/1",
          progress = "Cast Fire Blast on Stonetusk Boar: 0/1",
          quest = "Cast Fire Blast on Stonetusk Boar",
          full = "Cast Fire Blast on Stonetusk Boar"
        }
      },
      {
        objective = "cast-spell: { spell: 'Fire Blast', guild: Theramore Guard }",
        expected = {
          log = "Fire Blast on <Theramore Guard> member 0/1",
          progress = "Cast Fire Blast on <Theramore Guard> member: 0/1",
          quest = "Cast Fire Blast on <Theramore Guard> member",
          full = "Cast Fire Blast on <Theramore Guard> member",
        }
      },
      {
        objective = "cast-spell: { spell: 'Fire Blast', class: Druid }",
        expected = {
          log = "Fire Blast on Druid 0/1",
          progress = "Cast Fire Blast on Druid: 0/1",
          quest = "Cast Fire Blast on Druid",
          full = "Cast Fire Blast on Druid",
        }
      },
      {
        objective = "cast-spell: { spell: 'Fire Blast', level: 30 }",
        expected = {
          log = "Fire Blast on Level 30+ foe 0/1",
          progress = "Cast Fire Blast on Level 30+ foe: 0/1",
          quest = "Cast Fire Blast on Level 30+ foe",
          full = "Cast Fire Blast on Level 30+ foe",
        }
      },
      {
        objective = "cast-spell: { spell: 'Fire Blast', faction: Horde }",
        expected = {
          log = "Fire Blast on Horde foe 0/1",
          progress = "Cast Fire Blast on Horde foe: 0/1",
          quest = "Cast Fire Blast on Horde foe",
          full = "Cast Fire Blast on Horde foe",
        }
      },
      {
        objective = "cast-spell: { spell: 'Fire Blast', guild: Theramore Guard, class: Druid, level: 30, faction: Horde }",
        expected = {
          log = "Fire Blast on Level 30+ Horde <Theramore Guard> Druid 0/1",
          progress = "Cast Fire Blast on Level 30+ Horde <Theramore Guard> Druid: 0/1",
          quest = "Cast Fire Blast on Level 30+ Horde <Theramore Guard> Druid",
          full = "Cast Fire Blast on Level 30+ Horde <Theramore Guard> Druid",
        }
      },
    }
    for num, tc in ipairs(testCases) do
      local script = objectiveScriptTemplate..tc.objective
      local quest = compiler:Compile(script)

      local objective = quest.objectives[1]

      for scope, ex in pairs(tc.expected) do
        it("can parse display text (#"..num..", "..scope..")", function()
          -- print("===== Test Case #"..num..", "..scope.." =====")
          -- addon:ForceLogs(function()
          local text = getDisplayText(objective, scope)
          assert.equals(ex, text)
          -- end)
        end)
      end
    end
  end)
  describe("custom text parameters", function()
    it("can accept simple text overrides", function()
      local script = [[
        quest:
          name: Parser test
        objectives:
          - kill:
              target: Chicken
              text: "%t obliterated: %p/%g"
      ]]
      local quest = compiler:Compile(script)
      local obj = quest.objectives[1]
      assert.equals("Chicken obliterated: 0/1", getDisplayText(obj, "log"))
      assert.equals("Chicken obliterated: 0/1", getDisplayText(obj, "progress"))
      assert.equals("Chicken obliterated: 0/1", getDisplayText(obj, "quest"))
      assert.equals("Kill Chicken", getDisplayText(obj, "full")) -- Cannot be overridden
    end)
    it("can accept partial text overrides", function()
      local script = [[
        quest:
          name: Parser test
        objectives:
          - kill:
              target: Chicken
              text:
                quest: Commit an unthinkable atrocity against %t
      ]]
      local quest = compiler:Compile(script)
      local obj = quest.objectives[1]
      assert.equals("Chicken 0/1", getDisplayText(obj, "log"))
      assert.equals("Chicken slain: 0/1", getDisplayText(obj, "progress"))
      assert.equals("Commit an unthinkable atrocity against Chicken", getDisplayText(obj, "quest"))
      assert.equals("Kill Chicken", getDisplayText(obj, "full"))
    end)
    it("can accept complete text overrides", function()
      local script = [[
        quest:
          name: Parser test
        objectives:
          - kill:
              target: Chicken
              text:
                log: Be kind to %t
                progress: "%t SAVED: %p/%g"
                quest: This isn't a genocide playthrough, you know
      ]]
      local quest = compiler:Compile(script)
      local obj = quest.objectives[1]
      assert.equals("Be kind to Chicken", getDisplayText(obj, "log"))
      assert.equals("Chicken SAVED: 0/1", getDisplayText(obj, "progress"))
      assert.equals("This isn't a genocide playthrough, you know", getDisplayText(obj, "quest"))
      assert.equals("Kill Chicken", getDisplayText(obj, "full"))
    end)
  end)
  describe("startcomplete display text", function()
    local testCases = {
      {
        start = "{ zone: Elwynn Forest }",
        expected = {
          log = "Go to Elwynn Forest.",
          quest = "Go to Elwynn Forest.",
          full = "Go to Elwynn Forest.",
        }
      },
      {
        start = "{ zone: Elwynn Forest, subzone: Goldshire }",
        expected = {
          log = "Go to Goldshire.",
          quest = "Go to Goldshire in Elwynn Forest.",
          full = "Go to Goldshire in Elwynn Forest.",
        }
      },
      {
        start = "{ zone: Elwynn Forest, coords: '22,15.1,0.4' }",
        expected = {
          log = "Go to Elwynn Forest.",
          quest = "Go to (22, 15.1) in Elwynn Forest.",
          full = "Go to (22, 15.1) +/- 0.4 in Elwynn Forest.",
        }
      },
      {
        start = "{ zone: Elwynn Forest, subzone: Goldshire, coords: '22,15.1,0.4' }",
        expected = {
          log = "Go to Goldshire.",
          quest = "Go to (22, 15.1) in Goldshire in Elwynn Forest.",
          full = "Go to (22, 15.1) +/- 0.4 in Goldshire in Elwynn Forest.",
        }
      },
      {
        start = "{ target: Innkeeper Farley }",
        expected = {
          log = "Target Innkeeper Farley.",
          quest = "Target Innkeeper Farley.",
          full = "Target Innkeeper Farley.",
        }
      },
      {
        start = "{ target: Bob, zone: Durotar }",
        expected = {
          log = "Target Bob in Durotar.",
          quest = "Target Bob in Durotar.",
          full = "Target Bob in Durotar.",
        }
      },
      {
        start = "{ target: Bob, zone: Durotar, subzone: Jaggedswine Farm }",
        expected = {
          log = "Target Bob at Jaggedswine Farm.",
          quest = "Target Bob at Jaggedswine Farm in Durotar.",
          full = "Target Bob at Jaggedswine Farm in Durotar.",
        }
      },
      {
        start = "{ target: Bob, zone: Durotar, coords: '13.81,71,1.3' }",
        expected = {
          log = "Target Bob in Durotar.",
          quest = "Target Bob at (13.81, 71) in Durotar.",
          full = "Target Bob at (13.81, 71) +/- 1.3 in Durotar.",
        }
      },
      {
        start = "{ target: Bob, zone: Durotar, subzone: Jaggedswine Farm, coords: '13.81,71,1.3' }",
        expected = {
          log = "Target Bob at Jaggedswine Farm.",
          quest = "Target Bob at (13.81, 71) in Jaggedswine Farm in Durotar.",
          full = "Target Bob at (13.81, 71) +/- 1.3 in Jaggedswine Farm in Durotar.",
        }
      },
    }
    for num, tc in ipairs(testCases) do
      local script = [[
        quest:
          name: Startcomplete displaytext parser test
        start: ]]..tc.start.."\n"..[[
        complete: ]]..tc.start
      local quest = compiler:Compile(script)

      for scope, ex in pairs(tc.expected) do
        it("can parse startcomplete text (#"..num..", "..scope..")", function()
          -- print("===== Test Case #"..num..", "..scope.." =====")
          -- addon:ForceLogs(function()
          local text = getDisplayText(quest.start, scope)
          assert.equals(ex, text)
          text = getDisplayText(quest.complete, scope)
          assert.equals(ex, text)
          -- end)
        end)
      end
    end
  end)
  describe("player information", function()
    before_each(function()
      game:ResetEnv(addon)
    end)
    it("can display the player's name", function()
      game:SetPlayerInfo(addon, { name = "Hank" })
      local str = addon:PopulateText("Good %name")
      assert.equals("Good Hank", str)
    end)
    it("can display the player's class", function()
      game:SetPlayerInfo(addon, { class = "Mage", classId = 1 })
      local str = addon:PopulateText("Not bad for a %class.")
      assert.equals("Not bad for a Mage.", str)
    end)
    it("can display the player's race", function()
      game:SetPlayerInfo(addon, { race = "Night Elf", raceId = 1 })
      local str = addon:PopulateText("You call yourself a %race?")
      assert.equals("You call yourself a Night Elf?", str)
    end)
    it("can display the player's guild", function()
      game:SetPlayerInfo(addon, { guild = "Rocket Surgery" })
      local str = addon:PopulateText("Welcome to <%guild>!")
      assert.equals("Welcome to <Rocket Surgery>!", str)
    end)
    it("can display based on the player's sex", function()
      game:SetPlayerInfo(addon, { sex = 2 })
      local text = "Look at [%gen:him|her]!"
      local str = addon:PopulateText(text)
      assert.equals("Look at him!", str)

      game:ResetEnv(addon)
      game:SetPlayerInfo(addon, { sex = 3 })
      str = addon:PopulateText(text)
      assert.equals("Look at her!", str)
    end)
  end)
  describe("quest information", function()
    local script = objectiveScriptTemplate.."kill 5 Chicken"
    before_each(function()
      game:ResetEnv(addon)
      addon.QuestLog:DeleteAll()
      addon.QuestCatalog:DeleteAll()
    end)
    it("can display the author's name", function()
      game:SetPlayerInfo(addon, { name = "Bobby" })
      local quest = compiler:Compile(script)

      local str = addon:PopulateText("Dang it, %author", quest)
      assert.equals("Dang it, Bobby", str)
    end)
    it("can display the sharer's name", function()
      local quest = compiler:Compile(script)
      game:SetPlayerInfo(addon, { name = "Peggy" })
      addon:ShareQuest(quest)
      addon:AcceptQuest(quest, true)

      local str = addon:PopulateText("Spa-%giver and meatballs", quest)
      assert.equals("Spa-Peggy and meatballs", str)
    end)
  end)
  describe("formatting", function()
    it("can add newline", function()
      local str = addon:PopulateText("new%n line")
      assert.equals("new\nline", str)
    end)
    it("can add line break", function()
      local str = addon:PopulateText("line%br break")
      assert.equals("line\n\nbreak", str)
    end)
  end)
end)