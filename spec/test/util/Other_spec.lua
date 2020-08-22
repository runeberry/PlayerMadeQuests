local mock = require("spec/mock")
local builder = require("spec/addon-builder")
local addon = builder:Build()

local logSpy = spy.on(addon.Logger, "Log")

describe("Identifiers", function()
  describe("CreateID", function()
    it("can create different sequential ids", function()
      local id1, id2 = addon:CreateID(), addon:CreateID()
      assert.not_equals(id1, id2)
    end)
    it("can create IDs with format strings", function()
      local format = "test-id-%i"
      local id = addon:CreateID(format)
      assert.not_equals(id, format)
    end)
  end)
  describe("ParseGUID", function()

  end)
end)

describe("Logger", function()
  before_each(function()
    addon.Logger.Log:clear()
  end)
  it("can log", function()
    addon.Logger:Info("test log %s", "more stuff")
    assert.spy(logSpy).was_called()
  end)
  it("can flush log buffer on startup", function()
    local tempAddon = builder:Build({ LOG_LEVEL = 4, LOG_MODE = "simple" })
    tempAddon.SILENT_PRINT = true
    local tempLogSpy = spy.on(tempAddon.Logger, "Log")
    local printSpy = mock:GetFunctionMock(tempAddon.G.print)
    tempAddon.Logger:Debug("buffered log")
    assert.spy(tempLogSpy).was_called()
    printSpy:AssertNotCalled()
    tempAddon:Init()
    tempAddon:Advance()
    printSpy:AssertCalled()
  end)
end)

describe("Sounds", function()
  local playSoundMock = mock:GetFunctionMock(addon.G.PlaySoundFile)

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

describe("Types", function()
  describe("ConvertValue", function()

  end)
  describe("TryConvertString", function()
      it("returns a number", function()
      local strNum = "1"
      local num = 1
      local actual = addon:TryConvertString(strNum)
      assert.equals(num, actual)
      end)
      
      it("returns a boolean", function()
      local strBool = "true"
      local bool = true
      local actual = addon:TryConvertString(strBool)
      assert.equals(bool, actual)
      end)
      it("returns a string", function()
      local strStr = "hello"
      local str = "hello"
      local actual = addon:TryConvertString(strStr)
      assert.equals(str, actual)
      end)
  end)
end)