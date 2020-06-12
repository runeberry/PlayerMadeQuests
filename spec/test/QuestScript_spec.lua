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
end)