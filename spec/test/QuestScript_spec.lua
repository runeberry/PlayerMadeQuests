local builder = require("spec/addon-builder")
local addon = builder:Build()
local compiler = addon.QuestScriptCompiler

describe("QuestScriptCompiler", function()
  setup(function()
    addon:Init()
    addon:Advance()
  end)
  it("can compile valid script", function()
    local script = [[
      quest:
        name: Hello World
      objectives:
        - kill something
    ]]
    compiler:Compile(script)
  end)
  it("cannot compile invalid script", function()
    local script = [[bad juju]]
    assert.has_error(function() compiler:Compile(script) end)
  end)
  it("can compile all demo quests", function()
    -- todo: move this test to QuestDemos tests, if I ever make that
    local demos = addon.QuestDemos:FindAll()
    for _, demo in ipairs(demos) do
      compiler:Compile(demo.script, demo.parameters)
    end
  end)
  describe("objective parse modes", function()
    local expected = {
      name = "Test Quest Name",
      questId = "test-quest-id",
      objectives = {
        {
          questId = "test-quest-id",
          name = "kill",
          progress = 0,
          goal = 1,
          conditions = {
            killtarget = { ["Cow"] = true }
          }
        },
        {
          questId = "test-quest-id",
          name = "kill",
          progress = 0,
          goal = 3,
          conditions = {
            killtarget = { ["Chicken"] = true }
          }
        },
        {
          questId = "test-quest-id",
          name = "kill",
          progress = 0,
          goal = 5,
          conditions = {
            killtarget = { ["Mangy Wolf"] = true }
          }
        }
      }
    }
    local quest = {
      name = expected.name,
      questId = "test-quest-id"
    }
    local function assertMatch(expected, yaml)
      local compiled = compiler:Compile(yaml, quest)
      for i, obj in ipairs(compiled.objectives) do
        assert(obj.id, "compiled objective should have an id")
        obj.id = nil -- objective ids are assigned at compile time, no need to match
        assert.same(expected.objectives[i], obj)
      end
    end
    it("can parse mode [1] (shorthand)", function()
      local yaml = [[
        objectives:
          - kill Cow
          - kill 3 Chicken
          - kill 5 "Mangy Wolf"
      ]]
      assertMatch(expected, yaml)
    end)
    it("can parse mode [2] (shorthand, w/ optional colon)", function()
      local yaml = [[
        objectives:
          - kill: Cow
          - kill: 3 Chicken
          - kill: 5 "Mangy Wolf"
      ]]
      assertMatch(expected, yaml)
    end)
    it("can parse mode [3] (mis-indented map)", function()
      local yaml = [[
        objectives:
          - kill:
            target: Cow
          - kill:
            goal: 3
            target: Chicken
          - kill:
            goal: 5
            target: Mangy Wolf
      ]]
      assertMatch(expected, yaml)
    end)
    it("can parse mode [4] (map, block form)", function()
      local yaml = [[
        objectives:
          - kill:
              target: Cow
          - kill:
              goal: 3
              target: Chicken
          - kill:
              goal: 5
              target: "Mangy Wolf" # quotes are optional here
      ]]
      assertMatch(expected, yaml)
    end)
    it("can parse mode [4] (map, flow form)", function()
      local yaml = [[
        objectives:
          - kill: { target: Cow }
          - kill: { goal: 3, target: Chicken }
          - kill: { goal: 5, target: Mangy Wolf }
      ]]
      assertMatch(expected, yaml)
    end)
  end)
  describe("display text parser", function()
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
        objective = "explore Westfall 25.2 38.4",
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
        objective = "explore: { zone: Elwynn Forest, posx: 32, posy: 20, radius: 5 }",
        expected = {
          log = "Go to Point #1 in Elwynn Forest",
          progress = "Point #1 in Elwynn Forest explored: 0/1",
          quest = "Explore Point #1 in Elwynn Forest",
          full = "Go within 5 units of (32, 20) in Elwynn Forest"
        }
      },
      {
        objective = "explore: { zone: Elwynn Forest, subzone: Goldshire, posx: 32, posy: 20, radius: 5 }",
        expected = {
          log = "Go to Point #1 in Goldshire",
          progress = "Point #1 in Goldshire explored: 0/1",
          quest = "Explore Point #1 in Goldshire in Elwynn Forest",
          full = "Go within 5 units of (32, 20) in Goldshire in Elwynn Forest"
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
          name: Display text parser test
        objectives:
          - ]]..tc.objective
      local quest = compiler:Compile(script)

      local objective = quest.objectives[1]

      for scope, ex in pairs(tc.expected) do
        it("can parse display text (#"..num..", "..scope..")", function()
          -- print("===== Test Case #"..num..", "..scope.." =====")
          local text = compiler:GetDisplayText(objective, scope)
          assert.equals(ex, text)
        end)
      end
    end
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
        assert.equals("Chicken obliterated: 0/1", compiler:GetDisplayText(obj, "log"))
        assert.equals("Chicken obliterated: 0/1", compiler:GetDisplayText(obj, "progress"))
        assert.equals("Chicken obliterated: 0/1", compiler:GetDisplayText(obj, "quest"))
        assert.equals("Kill Chicken", compiler:GetDisplayText(obj, "full")) -- Cannot be overridden
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
        assert.equals("Chicken 0/1", compiler:GetDisplayText(obj, "log"))
        assert.equals("Chicken slain: 0/1", compiler:GetDisplayText(obj, "progress"))
        assert.equals("Commit an unthinkable atrocity against Chicken", compiler:GetDisplayText(obj, "quest"))
        assert.equals("Kill Chicken", compiler:GetDisplayText(obj, "full"))
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
        assert.equals("Be kind to Chicken", compiler:GetDisplayText(obj, "log"))
        assert.equals("Chicken SAVED: 0/1", compiler:GetDisplayText(obj, "progress"))
        assert.equals("This isn't a genocide playthrough, you know", compiler:GetDisplayText(obj, "quest"))
        assert.equals("Kill Chicken", compiler:GetDisplayText(obj, "full"))
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
        assert.equals("Complete task #1", compiler:GetDisplayText(objs[2]))
        assert.equals("Complete task #2", compiler:GetDisplayText(objs[4]))
        assert.equals("Complete task #3", compiler:GetDisplayText(objs[5]))
      end)
    end)
  end)
end)