local builder = require("spec/addon-builder")
local addon = builder:Build()
local compiler = addon.QuestScriptCompiler

-- Literally just lazy shorthand
local function compile(script, params)
  return compiler:Compile(script, params)
end

local function compile_err(script, params)
  assert.has_error(function() compiler:Compile(script, params) end)
end

describe("QuestScriptCompiler", function()
  local tc, script

  setup(function()
    addon:Init()
  end)
  before_each(function()
    script = nil
    tc = {}
  end)

  it("can compile valid script", function()
    script = [[objective kill something]]
    compile(script)
  end)
  it("cannot compile invalid script", function()
    script = [[bad juju]]
    compile_err(script)
  end)
  it("can recognize command aliases", function()
    script = [[obj kill something
    o talkto something]]
    compile(script)
  end)
  it("can compile all demo quests", function()
    -- todo: move this test to QuestDemos tests, if I ever make that
    local demos = addon.QuestDemos:FindAll()
    for _, demo in ipairs(demos) do
      compile(demo.script, demo.parameters)
    end
  end)
  describe("type coercion", function()
    it("can recognize quoted string values", function()
      script = [[quest name="Adventure Quest"]]
      local result = compile(script)
      assert.same("Adventure Quest", result.name)
    end)
    it("can recognize number values", function()
      -- todo: this won't work once type validation is in place
      tc = { 10, 1, 0, -1, -10 }
      for _, v in ipairs(tc) do
        script = string.format("quest name=%s", v)
        local result = compile(script)
        assert.same(v, result.name)
      end
    end)
    it("can recognize boolean true", function()
      -- todo: this won't work once type validation is in place
      script = "quest name=true"
      local result = compile(script)
      assert.same(true, result.name)
    end)
    -- it("can recognize boolean false", function()
    --   -- todo: this won't work once type validation is in place
    --   script = "quest name=false"
    --   local result = compile(script)
    --   assert.same(false, result.name)
    -- end)
    it("can recognize unquoted string values", function()
      script = [[quest name=AdventureQuest]]
      local result = compile(script)
      assert.same("AdventureQuest", result.name)
    end)
  end)
end)