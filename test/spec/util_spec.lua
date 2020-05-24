local mock = require("mock")
local addon = require("addon-builder"):Build()

local logSpy = spy.on(addon.Logger, "Log")

describe("Identifiers", function()

end)

describe("Logger", function()

end)

describe("Sounds", function()
  local playSoundMock = mock:GetMock(addon.G.PlaySoundFile)

  before_each(function()
    addon.Logger.Log:clear()
    playSoundMock:Reset()
  end)

  it("can play a recognized sound", function()
    addon:PlaySound("QuestAccepted")
    playSoundMock:AssertCalled()
  end)
  it("warns when an unrecognized sound is requested", function()
    addon:PlaySound("literally whatever")
    assert.spy(logSpy).was_called()
    playSoundMock:AssertNotCalled()
  end)
end)

describe("Strings", function()

end)

describe("Tables", function()

end)