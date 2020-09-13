local builder = require("spec/addon-builder")
local events = require("spec/events")

describe("VersionCheck", function()
  describe("when the addon is loaded", function()
    local tempAddon, tempEventSpy
    before_each(function()
      tempAddon = builder:Build()
      tempEventSpy = events:SpyOnEvents(tempAddon.MessageEvents)
    end)
    it("can send out a version request", function()
      tempAddon:Init()
      tempEventSpy:AssertPublished("AddonVersionRequest")
    end)
  end)
  describe("when a version request is received", function()
    local addon, eventSpy
    local branch = "unit-test"

    local function publish(v, b)
      addon.MessageEvents:Publish("AddonVersionRequest", nil, v, b)
    end

    before_each(function()
      addon = builder:Build()
      addon:Init()
      addon:Advance()
      eventSpy = events:SpyOnEvents(addon.MessageEvents)
    end)
    it("newer versions are cached", function()
      publish(addon.VERSION + 1, branch)
      addon:Advance()

      local kvi = addon.SaveData:LoadTable("KnownVersionInfo", true)
      assert.equals(addon.VERSION + 1, kvi.version)
      assert.equals(branch, kvi.branch)
    end)
    it("same version is not cached", function()
      publish(addon.VERSION, branch)
      addon:Advance()

      local kvi = addon.SaveData:LoadTable("KnownVersionInfo", true)
      assert.equals(addon.VERSION, kvi.version)
      assert.equals(addon.BRANCH, kvi.branch)
    end)
    it("older version is not cached", function()
      publish(addon.VERSION - 1, branch)
      addon:Advance()

      local kvi = addon.SaveData:LoadTable("KnownVersionInfo", true)
      assert.equals(addon.VERSION, kvi.version)
      assert.equals(addon.BRANCH, kvi.branch)
    end)
    it("a version response is returned", function()
      publish(addon.VERSION, branch)
      addon:Advance()

      eventSpy:AssertPublished("AddonVersionResponse")
    end)
  end)
  describe("when a version response is received", function()
    local addon, eventSpy

    before_each(function()
      addon = builder:Build()
      addon:Init()
      addon:Advance()
      eventSpy = events:SpyOnEvents(addon.MessageEvents)
    end)
    it("a version response is not published", function()
      addon.MessageEvents:Publish("AddonVersionResponse", nil, addon.VERSION, addon.BRANCH)
      eventSpy:Reset() -- Don't count ^ this response in the spy
      addon:Advance()

      eventSpy:AssertNotPublished("AddonVersionResponse")
    end)
  end)
end)