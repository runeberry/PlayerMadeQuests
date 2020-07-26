local addon = require("spec/addon-builder"):Build()
local compiler, localizer = addon.QuestScriptCompiler, addon.QuestScriptLocalizer

describe("QuestScriptLocalizer", function()
  setup(function()
    addon:Init()
    addon:Advance()
  end)
  describe("objective displaytext parser", function()
    local testCases = {
      {
        objective = "emote dance Chicken",
        expected = {
          log = "/dance with Chicken",
          progress = "/dance with Chicken: 0/1",
          quest = "/dance with Chicken",
          full = "Use emote /dance on Chicken"
        }
      },
      {
        objective = "emote fart 5 'Stormwind Guard'",
        expected = {
          log = "/fart with Stormwind Guard 0/5",
          progress = "/fart with Stormwind Guard: 0/5",
          quest = "/fart with 5 Stormwind Guard",
          full = "Use emote /fart on 5 Stormwind Guard"
        }
      },
      {
        objective = "emote cry",
        expected = {
          log = "/cry",
          progress = "/cry: 0/1",
          quest = "/cry",
          full = "Use emote /cry"
        }
      },
      {
        objective = "emote flex 3",
        expected = {
          log = "/flex 0/3",
          progress = "/flex: 0/3",
          quest = "/flex 3 times",
          full = "Use emote /flex 3 times"
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
          log = "Go to Point #1 in Westfall",
          progress = "Point #1 in Westfall explored: 0/1",
          quest = "Explore Point #1 in Westfall",
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
          log = "Go to Point #1 in Elwynn Forest",
          progress = "Point #1 in Elwynn Forest explored: 0/1",
          quest = "Explore Point #1 in Elwynn Forest",
          full = "Go to (32, 20) +/- 5 in Elwynn Forest"
        }
      },
      {
        objective = "explore: { zone: Elwynn Forest, subzone: Goldshire, coords: \"32,20,5\" }",
        expected = {
          log = "Go to Point #1 in Goldshire",
          progress = "Point #1 in Goldshire explored: 0/1",
          quest = "Explore Point #1 in Goldshire in Elwynn Forest",
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
        objective = "talkto Rexxar",
        expected = {
          log = "Talk to Rexxar",
          progress = "Talk to Rexxar: 0/1",
          quest = "Talk to Rexxar",
          full = "Talk to Rexxar"
        }
      },
      {
        objective = "talkto 2 'Stormwind Guard'",
        expected = {
          log = "Talk to Stormwind Guard 0/2",
          progress = "Talk to Stormwind Guard: 0/2",
          quest = "Talk to 2 Stormwind Guard",
          full = "Talk to 2 Stormwind Guard"
        }
      },
    }
    for num, tc in ipairs(testCases) do
      local script = [[
        quest:
          name: Objective displaytext parser test
        objectives:
          - ]]..tc.objective
      local quest = compiler:Compile(script)

      local objective = quest.objectives[1]

      for scope, ex in pairs(tc.expected) do
        it("can parse display text (#"..num..", "..scope..")", function()
          -- print("===== Test Case #"..num..", "..scope.." =====")
          -- addon:ForceLogs(function()
          local text = localizer:GetDisplayText(objective, scope)
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
      assert.equals("Chicken obliterated: 0/1", localizer:GetDisplayText(obj, "log"))
      assert.equals("Chicken obliterated: 0/1", localizer:GetDisplayText(obj, "progress"))
      assert.equals("Chicken obliterated: 0/1", localizer:GetDisplayText(obj, "quest"))
      assert.equals("Kill Chicken", localizer:GetDisplayText(obj, "full")) -- Cannot be overridden
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
      assert.equals("Chicken 0/1", localizer:GetDisplayText(obj, "log"))
      assert.equals("Chicken slain: 0/1", localizer:GetDisplayText(obj, "progress"))
      assert.equals("Commit an unthinkable atrocity against Chicken", localizer:GetDisplayText(obj, "quest"))
      assert.equals("Kill Chicken", localizer:GetDisplayText(obj, "full"))
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
      assert.equals("Be kind to Chicken", localizer:GetDisplayText(obj, "log"))
      assert.equals("Chicken SAVED: 0/1", localizer:GetDisplayText(obj, "progress"))
      assert.equals("This isn't a genocide playthrough, you know", localizer:GetDisplayText(obj, "quest"))
      assert.equals("Kill Chicken", localizer:GetDisplayText(obj, "full"))
    end)
    it("can use the %inc var properly", function()
      local script = [[
        quest:
          name: inc test
        objectives:
          - explore Durotar
          - kill:
              target: Swine
              goal: 5
              text: "Complete task #%inc"
          - talkto: Orgrimmar Grunt
          - kill:
              target: Bloodtalon Scythemaw
              goal: 3
              text: "Complete task #%inc"
          - explore:
              zone: Durotar
              subzone: Skull Rock
              text: "Complete task #%inc"
      ]]
      local quest = compiler:Compile(script)
      local objs = quest.objectives
      assert.equals("Complete task #1", localizer:GetDisplayText(objs[2]))
      assert.equals("Complete task #2", localizer:GetDisplayText(objs[4]))
      assert.equals("Complete task #3", localizer:GetDisplayText(objs[5]))
      -- Run tests again to ensure that the values persist on each GetDisplayText call
      assert.equals("Complete task #1", localizer:GetDisplayText(objs[2]))
      assert.equals("Complete task #2", localizer:GetDisplayText(objs[4]))
      assert.equals("Complete task #3", localizer:GetDisplayText(objs[5]))
    end)
  end)
  describe("startcomplete display text", function()
    local testCases = {
      {
        start = "{ zone: Elwynn Forest }",
        expected = {
          log = "Go to Elwynn Forest",
          quest = "Go to Elwynn Forest",
          full = "Go to Elwynn Forest",
        }
      },
      {
        start = "{ zone: Elwynn Forest, subzone: Goldshire }",
        expected = {
          log = "Go to Goldshire",
          quest = "Go to Goldshire in Elwynn Forest",
          full = "Go to Goldshire in Elwynn Forest",
        }
      },
      {
        start = "{ zone: Elwynn Forest, coords: '22,15.1,0.4' }",
        expected = {
          log = "Go to Elwynn Forest",
          quest = "Go to (22, 15.1) in Elwynn Forest",
          full = "Go to (22, 15.1) +/- 0.4 in Elwynn Forest",
        }
      },
      {
        start = "{ zone: Elwynn Forest, subzone: Goldshire, coords: '22,15.1,0.4' }",
        expected = {
          log = "Go to Goldshire",
          quest = "Go to (22, 15.1) in Goldshire in Elwynn Forest",
          full = "Go to (22, 15.1) +/- 0.4 in Goldshire in Elwynn Forest",
        }
      },
      {
        start = "{ target: Innkeeper Farley }",
        expected = {
          log = "Go to Innkeeper Farley",
          quest = "Go to Innkeeper Farley",
          full = "Go to Innkeeper Farley",
        }
      },
      {
        start = "{ target: Bob, zone: Durotar }",
        expected = {
          log = "Go to Bob in Durotar",
          quest = "Go to Bob in Durotar",
          full = "Go to Bob in Durotar",
        }
      },
      {
        start = "{ target: Bob, zone: Durotar, subzone: Jaggedswine Farm }",
        expected = {
          log = "Go to Bob at Jaggedswine Farm",
          quest = "Go to Bob at Jaggedswine Farm in Durotar",
          full = "Go to Bob at Jaggedswine Farm in Durotar",
        }
      },
      {
        start = "{ target: Bob, zone: Durotar, coords: '13.81,71,1.3' }",
        expected = {
          log = "Go to Bob in Durotar",
          quest = "Go to Bob at (13.81, 71) in Durotar",
          full = "Go to Bob at (13.81, 71) +/- 1.3 in Durotar",
        }
      },
      {
        start = "{ target: Bob, zone: Durotar, subzone: Jaggedswine Farm, coords: '13.81,71,1.3' }",
        expected = {
          log = "Go to Bob at Jaggedswine Farm",
          quest = "Go to Bob at (13.81, 71) in Jaggedswine Farm in Durotar",
          full = "Go to Bob at (13.81, 71) +/- 1.3 in Jaggedswine Farm in Durotar",
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
          local text = localizer:GetDisplayText(quest.start, scope)
          assert.equals(ex, text)
          text = localizer:GetDisplayText(quest.complete, scope)
          assert.equals(ex, text)
          -- end)
        end)
      end
    end
  end)
end)