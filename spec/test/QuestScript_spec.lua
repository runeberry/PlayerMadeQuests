local addon = require("spec/addon-builder"):Build()
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
  it("can supply default properties", function()
    local script = [[
      quest:
        name: Hello World
    ]]
    local quest = compiler:Compile(script)
    assert.is_string(quest.questId)
    assert.is_table(quest.objectives)
  end)
  it("can override questId with parameters", function()
    local params = { name = "Test quest", questId = "id-override" }
    local quest = compiler:Compile(nil, params)
    assert.equals(params.questId, quest.questId)
  end)
  it("can supply additional parameters", function()
    local params = { name = "Test quest", demoId = "extra-property" }
    local quest = compiler:Compile(nil, params)
    assert.equals(params.demoId, quest.demoId)
  end)
  it("can compile all demo quests", function()
    -- todo: (#49) move this test to QuestDemos tests, if I ever make that
    -- https://github.com/dolphinspired/PlayerMadeQuests/issues/49
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
end)