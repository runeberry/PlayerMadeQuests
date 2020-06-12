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

describe("QuestScript", function()
  setup(function()
    addon:Init()
  end)

  it("can compile valid script", function()
    compile([[objective kill something]])
  end)
  it("cannot compile invalid script", function()
    compile_err([[bad juju]])
  end)
end)