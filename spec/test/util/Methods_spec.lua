local addon = require("spec/addon-builder"):Build()

describe("Tables", function()
  describe("ApplyMethods", function()
    it("can apply methods to an object", function()
      local obj = {
        Value = 1,
      }
      local methods = {
        Property = 3,
        ["DoThing"] = function() end,
        ["DoOtherThing"] = function() end,
      }

      addon:ApplyMethods(obj, methods)

      assert.equals(methods.DoThing, obj.DoThing)
      assert.equals(methods.DoOtherThing, obj.DoOtherThing)
      assert.is_nil(obj.Property)
    end)
    it("cannot overwrite methods on an object without force", function()
      local obj = {
        ["DoThing"] = function() end,
      }
      local methods = {
        ["DoThing"] = function() end,
      }

      addon:ApplyMethods(obj, methods)

      assert.not_equals(methods.DoThing, obj.DoThing)
    end)
    it("can overwrite methods on an object with force", function()
      local obj = {
        ["DoThing"] = function() end,
      }
      local methods = {
        ["DoThing"] = function() end,
      }

      addon:ApplyMethods(obj, methods, true)

      assert.equals(methods.DoThing, obj.DoThing)
    end)
  end)

  describe("HookMethods", function()
    it("can pre-hook a method", function()
      local currentValue = nil
      local origCalled = 0
      local hookCalled = 0

      local obj = {
        ["DoThing"] = function(self, val)
          origCalled = origCalled + 1
          currentValue = "original"
        end
      }
      local methods = {
        ["DoThing"] = function(self, val)
          hookCalled = hookCalled + 1
          currentValue = val
        end
      }

      addon:HookMethods(obj, methods, addon.HookType.PreHook)
      obj:DoThing("hook")

      assert.equals(1, origCalled)
      assert.equals(1, hookCalled)
      assert.equals("original", currentValue)
    end)
    it("can post-hook a method", function()
      local currentValue = nil
      local origCalled = 0
      local hookCalled = 0

      local obj = {
        ["DoThing"] = function(self, val)
          origCalled = origCalled + 1
          currentValue = "original"
        end
      }
      local methods = {
        ["DoThing"] = function(self, val)
          hookCalled = hookCalled + 1
          currentValue = val
        end
      }

      addon:HookMethods(obj, methods, addon.HookType.PostHook)
      obj:DoThing("hook")

      assert.equals(1, origCalled)
      assert.equals(1, hookCalled)
      assert.equals("hook", currentValue)
    end)
    it("can create method to hook when property is nil", function()
      local currentValue = nil
      local hookCalled = 0

      local obj = {}
      local methods = {
        ["DoThing"] = function(self, val)
          hookCalled = hookCalled + 1
          currentValue = val
        end
      }

      addon:HookMethods(obj, methods)
      obj:DoThing("hook")

      assert.equals(1, hookCalled)
      assert.equals("hook", currentValue)
    end)
    it("can hook a single method", function()
      local currentValue = nil
      local origCalled = 0
      local hookCalled = 0

      local obj = {
        ["DoThing"] = function(self, val)
          origCalled = origCalled + 1
          currentValue = "original"
        end
      }
      local handler = function(self, val)
        hookCalled = hookCalled + 1
        currentValue = val
      end

      addon:HookMethod(obj, "DoThing", handler)
      obj:DoThing("hook")

      assert.equals(1, origCalled)
      assert.equals(1, hookCalled)
      assert.equals("hook", currentValue)
    end)
  end)
end)