local builder = require("spec/addon-builder")
local addon = builder:Build()
local compiler = addon.QuestScriptCompiler

describe("QuestScriptCompiler", function()
  setup(function()
    addon:Init()
  end)
  it("can compile valid script", function()
    local script = [[
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
      objectives = {
        {
          name = "kill",
          progress = 0,
          goal = 1,
          conditions = {
            target = { ["Cow"] = true }
          }
        },
        {
          name = "kill",
          progress = 0,
          goal = 3,
          conditions = {
            target = { ["Chicken"] = true }
          }
        },
        {
          name = "kill",
          progress = 0,
          goal = 5,
          conditions = {
            target = { ["Mangy Wolf"] = true }
          }
        }
      }
    }
    local quest = {
      name = "Test Quest Name"
    }
    local function assertMatch(expected, yaml)
      local compiled = compiler:Compile(yaml, quest)
      for i, obj in ipairs(compiled.objectives) do
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
          -- Expecting Point #0 because %inc doesn't work until quest is built
          log = "Go to Point #0 in Westfall",
          progress = "Point #0 in Westfall explored: 0/1",
          quest = "Explore Point #0 in Westfall",
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
          log = "Go to Point #0 in Elwynn Forest",
          progress = "Point #0 in Elwynn Forest explored: 0/1",
          quest = "Explore Point #0 in Elwynn Forest",
          full = "Go within 5 units of (32, 20) in Elwynn Forest"
        }
      },
      {
        objective = "explore: { zone: Elwynn Forest, subzone: Goldshire, posx: 32, posy: 20, radius: 5 }",
        expected = {
          log = "Go to Point #0 in Goldshire",
          progress = "Point #0 in Goldshire explored: 0/1",
          quest = "Explore Point #0 in Goldshire in Elwynn Forest",
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
  end)
end)