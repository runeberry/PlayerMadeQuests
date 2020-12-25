local mock = require("spec/mock")
local builder = require("spec/addon-builder")
local addon = builder:Build()

addon.Logger = mock:NewMock(addon.Logger)
local logSpy = mock:GetFunctionMock(addon.Logger.Log)

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
  describe("CreateGlobalName", function()
    it("can create new global name", function()
      local name = addon:CreateGlobalName("BeagleFrame")
      assert.equals("PMQ_BeagleFrame", name)
    end)
    it("can increment existing global name", function()
      local name1 = addon:CreateGlobalName("HoundFrame-%i")
      local name2 = addon:CreateGlobalName("HoundFrame-%i")
      local name3 = addon:CreateGlobalName("HoundFrame-%i")

      assert.equals("PMQ_HoundFrame-1", name1)
      assert.equals("PMQ_HoundFrame-2", name2)
      assert.equals("PMQ_HoundFrame-3", name3)
    end)
    it("cannot return name for non-string pattern", function()
      assert.has_error(function() addon:CreateGlobalName(1234) end)
    end)
  end)
  describe("ParseGUID", function()
    it("can parse player GUIDs", function()
      local playerGUID = "Player-970-0002FD64"
      local expectedType = "Player"
      local expectedServerID = "970"
      local expectedUID = "0002FD64"
      local actual = addon:ParseGUID(playerGUID)
      assert.equals(expectedType, actual.type)
      assert.equals(expectedServerID, actual.serverID)
      assert.equals(expectedUID, actual.UID)
    end)
    it("can parse item GUIDs", function()
      local itemGUID = "Item-970-0-400000076620BFF4"
      local expectedType = "Item"
      local expectedServerID = "970"
      local expectedUID = "400000076620BFF4"
      local actual = addon:ParseGUID(itemGUID)
      assert.equals(expectedType, actual.type)
      assert.equals(expectedServerID, actual.serverID)
      assert.equals(expectedUID, actual.UID)
    end)
    it("can parse creature, pet, object, or vehicle GUIDs", function()
      local cpovGUID = "Creature-0-970-0-11-31146-000136DF91"
      local expectedType = "Creature"
      local expectedServerID = "970"
      local expectedInstanceID = "0"
      local expectedZoneUID = "11"
      local expectedID = "31146"
      local expectedSpawnUID = "000136DF91"
      local actual = addon:ParseGUID(cpovGUID)
      assert.equals(expectedType, actual.type)
      assert.equals(expectedServerID, actual.serverID)
      assert.equals(expectedInstanceID, actual.instanceID)
      assert.equals(expectedZoneUID, actual.zoneUID)
      assert.equals(expectedID, actual.ID)
      assert.equals(expectedSpawnUID, actual.spawnUID)
    end)
    it("throws an error for an unrecognized format", function()
      local badGUID = "hello"
      assert.has_error(function()
        addon:ParseGUID(badGUID)
      end)
    end)
  end)
end)

describe("Logger", function()
  before_each(function()
    logSpy:Reset()
  end)
  it("can log", function()
    addon.Logger:Info("test log %s", "more stuff")
    logSpy:AssertCalled()
  end)
  it("can flush log buffer on init", function()
    local tempAddon = builder:Build()
    tempAddon.Logger:Debug("buffered log")
    assert.equals(0, tempAddon:GetLogStats()["*"].stats.received, "Expected no logs to be received before init")
    -- tempAddon:ForceLogs(function() tempAddon:Init() end)
    tempAddon:Init()
    assert.is_true(tempAddon:GetLogStats()["*"].stats.received > 0, "Expected logs to be flushed on init")
  end)
end)

describe("Sounds", function()
  local playSoundMock = mock:GetFunctionMock(addon.G.PlaySoundFile)

  before_each(function()
    logSpy:Reset()
    playSoundMock:Reset()
  end)

  it("can play a recognized sound", function()
    addon:PlaySound("QuestAccepted")
    playSoundMock:AssertCalled()
  end)
  it("warns when an unrecognized sound is requested", function()
    addon:PlaySound("literally whatever")
    logSpy:AssertCalled()
    playSoundMock:AssertNotCalled()
  end)
end)

describe("Types", function()
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