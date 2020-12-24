local addon = require("spec/addon-builder"):Build()

describe("Tables", function()
  local t
  before_each(function()
    t = {
      _temp = "temp value",
      rootName = "table name",
      rootValue = 42,
      flag = true,
      fn = function() end,
      table = {
        ["id1"] = { name = "tableItem1", val = 1 },
        ["id2"] = { name = "tableItem2", val = 2 },
        ["id3"] = { name = "tableItem3", val = 3 },
      },
      array = {
        { name = "arrayItem1", val = 1 },
        { name = "arrayItem2", val = 2 },
        { name = "arrayItem3", val = 3 },
      },
      set = {
        [{ name = "setItem1", val = 1 }] = true,
        [{ name = "setItem2", val = 2 }] = true,
        [{ name = "setItem3", val = 3 }] = true,
      },
      mixed = {
        { name = "arrayItem1", val = 1 },
        { name = "arrayItem2", val = 2 },
        ["id1"] = { name = "tableItem1", val = 1 },
        ["id2"] = { name = "tableItem2", val = 2 },
      }
    }
  end)

  describe("tlen", function()
    it("can return table length", function()
      assert.equals(3, addon:tlen(t.table))
      assert.equals(3, addon:tlen(t.array))
      assert.equals(3, addon:tlen(t.set))
      assert.equals(9, addon:tlen(t))
    end)
    it("can return 0 length for nil tables", function()
      assert.equals(0, addon:tlen(nil))
    end)
  end)

  describe("CleanTable", function()
    it("can clean tables", function()
      local expected = addon:CopyTable(t)
      expected._temp = nil
      expected.fn = nil
      -- add some extra values to ensure that it can clean nested tables
      t.array[1].fn = function() end
      t.table["id1"]._temp = "temp value"
      t.table["id4"] = function() end
      addon:CleanTable(t)
      assert.same(expected, t)
    end)
    it("cannot clean a nil table", function()
      assert.has_error(function() addon:CleanTable(nil) end)
    end)
  end)

  describe("CopyTable", function()
    it("can copy a table", function()
      local tcopy = addon:CopyTable(t)
      assert.same(t, tcopy)
      assert.not_equals(t, tcopy)
    end)
    it("cannot copy a nil table", function()
      assert.has_error(function() addon:CopyTable(nil) end)
    end)
  end)

  describe("MergeTable", function()
    it("can merge onto existing values", function()
      local patch = {
        rootName = t.rootName.." updated",
        rootValue = t.rootValue + 50,
        fn = function() end,
        flag = not t.flag,
      }

      local expected = addon:CopyTable(t)
      expected.rootName = patch.rootName
      expected.rootValue = patch.rootValue
      expected.fn = patch.fn
      expected.flag = patch.flag

      local merged = addon:MergeTable(t, patch)

      assert.same(expected, merged)
    end)
    it("does not impact parameter tables", function()
      local patch = {
        rootName = t.rootName.." updated"
      }

      local tCopy = addon:CopyTable(t)
      local patchCopy = addon:CopyTable(patch)

      local merged = addon:MergeTable(t, patch)

      assert.same(t, tCopy)
      assert.same(patch, patchCopy)
      assert.not_equals(merged, t)
      assert.not_equals(merged, patch)
    end)
    it("can merge different value types", function()
      local patch = {
        rootName = function() end,
        rootValue = "different type",
        fn = 31,
        flag = { itsa = "table now" },
      }

      local expected = addon:CopyTable(t)
      expected.rootName = patch.rootName
      expected.rootValue = patch.rootValue
      expected.fn = patch.fn
      expected.flag = patch.flag

      local merged = addon:MergeTable(t, patch)

      assert.same(expected, merged)
    end)
    it("can merge nested table with matching keys", function()
      local patch = {
        table = {
          ["id1"] = { name = "another name" },
          ["id3"] = { value = 300 }
        },
      }

      local expected = addon:CopyTable(t.table)
      expected["id1"].name = patch.table["id1"].name
      expected["id3"].value = patch.table["id3"].value

      local merged = addon:MergeTable(t, patch)

      assert.same(expected, merged.table)
    end)
    it("can merge nested table with new keys", function()
      local patch = {
        table = {
          ["new_id"] = { name = "new table item", value = 123 }
        }
      }

      local expected = addon:CopyTable(t.table)
      expected["new_id"] = patch.table["new_id"]

      local merged = addon:MergeTable(t, patch)

      assert.same(expected, merged.table)
    end)
    it("can merge base array by appending items", function()
      local patch = {
        { name = "another name" },
        { value = 300 }
      }

      local expected = addon:CopyTable(t.array)
      expected[#expected+1] = patch[1]
      expected[#expected+1] = patch[2]

      local merged = addon:MergeTable(t.array, patch)

      assert.same(expected, merged)
    end)
    it("can merge nested array by appending items", function()
      local patch = {
        array = {
          [1] = { name = "another name" },
          [2] = { value = 300 }
        }
      }

      local expected = addon:CopyTable(t.array)
      expected[#expected+1] = patch.array[1]
      expected[#expected+1] = patch.array[2]

      local merged = addon:MergeTable(t, patch)

      assert.same(expected, merged.array)
    end)
    it("can merge mixed array and key-value table", function()
      local patch = {
        mixed = {
          [1] = { name = "another name" },
          ["newItem"] = { value = 300 },
        }
      }

      local expected = addon:CopyTable(t.mixed)
      expected[#expected+1] = patch.mixed[1]
      expected["newItem"] = patch.mixed["newItem"]

      local merged = addon:MergeTable(t, patch)

      assert.same(expected, merged.mixed)
    end)
    it("cannot merge nil tables", function()
      assert.has_error(function() addon:MergeTable(nil, { rootName = "new name" }) end)
      assert.has_error(function() addon:MergeTable(t, nil) end)
      assert.has_error(function() addon:MergeTable(nil,nil) end)
    end)
  end)

  describe("MergeOptionsTable", function()
    it("can merge custom options", function()
      local defaultOptions = {
        v1 = "v1",
        v2 = "v2",
      }
      local customOptions = {
        v2 = "custom-v2",
        v3 = "custom-v3",
      }

      local merged = addon:MergeOptionsTable(defaultOptions, customOptions)

      assert.equals(defaultOptions.v1, merged.v1)
      assert.equals(customOptions.v2, merged.v2)
      assert.equals(customOptions.v3, merged.v3)
    end)
    it("can copy default options if no custom options provided", function()
      local defaultOptions = {
        v1 = "v1",
        v2 = "v2",
      }

      local merged = addon:MergeOptionsTable(defaultOptions, nil)

      assert.equals(defaultOptions.v1, merged.v1)
      assert.equals(defaultOptions.v2, merged.v2)
    end)
    it("cannot merge nil default options", function()
      assert.has_error(function() addon:MergeOptionsTable(nil, {}) end)
    end)
    it("cannot merge non-table default options", function()
      assert.has_error(function() addon:MergeOptionsTable("non-table", {}) end)
    end)
    it("cannot merge non-table custom options", function()
      assert.has_error(function() addon:MergeOptionsTable({}, "non-table") end)
    end)
  end)

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

  describe("DistinctSet", function()
    it("can create a set from a table", function()
      local expected = {
        [t.table["id1"]] = true,
        [t.table["id2"]] = true,
        [t.table["id3"]] = true,
      }

      local set = addon:DistinctSet(t.table)

      assert.same(expected, set)
    end)
    it("can create a set from an array", function()
      local expected = {
        [t.array[1]] = true,
        [t.array[2]] = true,
        [t.array[3]] = true,
      }

      local set = addon:DistinctSet(t.array)

      assert.same(expected, set)
    end)
    it("does not impact the parameter table", function()
      local tcopy = addon:CopyTable(t.table)

      local set = addon:DistinctSet(t.table)

      assert.same(tcopy, t.table)
      assert.not_equals(t.table, set)
    end)
    it("cannot create a set from a nil table", function()
      assert.has_error(function() addon:DistinctSet(nil) end)
    end)
  end)

  describe("SetToArray", function()
    it("can create an array from a set", function()
      local array = addon:SetToArray(t.set)

      assert.equals(3, #array)
    end)
    it("does not impact the parameter set", function()
      local setCopy = addon:CopyTable(t.set)

      local array = addon:SetToArray(t.set)

      assert.same(setCopy, t.set)
      assert.not_equals(t.set, array)
    end)
    it("cannot create an array from a nil set", function()
      assert.has_error(function() addon:SetToArray(nil) end)
    end)
  end)

  describe("InvertTable", function()
    it("can invert a table", function()
      local expected = {
        [t.table["id1"]] = "id1",
        [t.table["id2"]] = "id2",
        [t.table["id3"]] = "id3",
      }

      local inverted = addon:InvertTable(t.table)

      assert.same(expected, inverted)
    end)
    it("can invert an array", function()
      local expected = {
        [t.array[1]] = 1,
        [t.array[2]] = 2,
        [t.array[3]] = 3,
      }

      local inverted = addon:InvertTable(t.array)

      assert.same(expected, inverted)
    end)
    it("does not impact the parameter table", function()
      local tableCopy = addon:CopyTable(t.table)

      local inverted = addon:InvertTable(t.table)

      assert.same(tableCopy, t.table)
      assert.not_equals(t.table, inverted)
    end)
    it("cannot invert a nil table", function()
      assert.has_error(function() addon:InvertTable(nil) end)
    end)
  end)

  describe("ConcatArray", function()
    it("cannot concat nil tables", function()
      -- ARRANGE
      local t1 = {}
      local t2 = nil

      -- ASSERT
      assert.has_error(function() addon:ConcatArray(t1, t2) end)
    end)
    it("can concat two array tables", function()
      -- ARRANGE
      local t1 = {
        "Midna",
        "Beedle",
        "Captain",
      }
      local t2 = { "Scout", "Tank", }

      -- ACT
      local actual = addon:ConcatArray(t1, t2)

      -- ASSERT
      local expected = {
        "Midna",
        "Beedle",
        "Captain",
        "Scout",
        "Tank",
      }
      assert.same(expected, actual)
    end)
  end)

  -- Even though compression/serialization are mocked out, it's worth
  -- testing to ensure the addon's logic is sound
  describe("Compression", function()
    it("can compress table", function()
      local compressed = addon:CompressTable(t)
      assert.is_string(compressed)
    end)
    it("can decompress table", function()
      local compressed = addon:CompressTable(t)
      local decompressed = addon:DecompressTable(compressed)

      assert.is_table(decompressed)
      assert.not_equals(t, decompressed)
    end)
    it("can clean table before compression", function()
      local compressed = addon:CompressTable(t)
      local decompressed = addon:DecompressTable(compressed)
      local expected = addon:CleanTable(addon:CopyTable(t))

      assert.same(expected, decompressed)
    end)
    it("cannot compress nil table", function()
      assert.has_error(function() addon:CompressTable(nil) end)
    end)
    it("can decompress nil to empty table", function()
      assert.same({}, addon:DecompressTable(nil))
    end)
    it("can decompress empty string to empty table", function()
      assert.same({}, addon:DecompressTable(""))
    end)
  end)

  describe("GetTableHash", function()
    it("can generate table hash", function()
      -- This method's dependencies are all mocked out so this doesn't test much
      -- other than that it doesn't throw any obvious errors
      assert.has_no_error(function() addon:GetTableHash({}) end)
    end)
  end)
end)

describe("Unpack", function()
  describe("RGBA", function()
    it("can unpack named values", function()
      local rgba = { r = 0.1, g = 0.2, b = 0.3, a = 0.4 }
      local r, g, b, a = addon:UnpackRGBA(rgba)
      assert.equals(rgba.r, r)
      assert.equals(rgba.g, g)
      assert.equals(rgba.b, b)
      assert.equals(rgba.a, a)
    end)
    it("can unpack missing named values", function()
      local rgba = { r = 0.1, b = 0.3 }
      local r, g, b, a = addon:UnpackRGBA(rgba)
      assert.equals(rgba.r, r)
      assert.equals(0.0, g)
      assert.equals(rgba.b, b)
      assert.equals(1.0, a)
    end)
    it("can unpack array values", function()
      local rgba = { 0.1, 0.2, 0.3, 0.4 }
      local r, g, b, a = addon:UnpackRGBA(rgba)
      assert.equals(rgba[1], r)
      assert.equals(rgba[2], g)
      assert.equals(rgba[3], b)
      assert.equals(rgba[4], a)
    end)
    it("can unpack missing array values", function()
      local rgba = { 0.1, 0.2 }
      local r, g, b, a = addon:UnpackRGBA(rgba)
      assert.equals(rgba[1], r)
      assert.equals(rgba[2], g)
      assert.equals(0.0, b)
      assert.equals(1.0, a)
    end)
    it("can unpack a number", function()
      local r, g, b, a = addon:UnpackRGBA(5)
      assert.equals(5, r)
      assert.equals(5, g)
      assert.equals(5, b)
      assert.equals(1.0, a)
    end)
    it("can unpack nil", function()
      local r, g, b, a = addon:UnpackRGBA()
      assert.equals(0.0, r)
      assert.equals(0.0, g)
      assert.equals(0.0, b)
      assert.equals(1.0, a)
    end)
  end)

  describe("LRTB", function()
    it("can unpack named values", function()
      local lrtb = { l = 1, r = 2, t = 3, b = 4 }
      local l, r, t, b = addon:UnpackLRTB(lrtb)
      assert.equals(lrtb.l, l)
      assert.equals(lrtb.r, r)
      assert.equals(lrtb.t, t)
      assert.equals(lrtb.b, b)
    end)
    it("can unpack missing named values", function()
      local lrtb = { r = 2, b = 4 }
      local l, r, t, b = addon:UnpackLRTB(lrtb)
      assert.equals(0, l)
      assert.equals(lrtb.r, r)
      assert.equals(0, t)
      assert.equals(lrtb.b, b)
    end)
    it("can unpack array values", function()
      local lrtb = { 1, 2, 3, 4 }
      local l, r, t, b = addon:UnpackLRTB(lrtb)
      assert.equals(lrtb[1], l)
      assert.equals(lrtb[2], r)
      assert.equals(lrtb[3], t)
      assert.equals(lrtb[4], b)
    end)
    it("can unpack missing array values", function()
      local lrtb = { 1, 2 }
      local l, r, t, b = addon:UnpackLRTB(lrtb)
      assert.equals(lrtb[1], l)
      assert.equals(lrtb[2], r)
      assert.equals(0, t)
      assert.equals(0, b)
    end)
    it("can unpack a number", function()
      local l, r, t, b = addon:UnpackLRTB(5)
      assert.equals(5, l)
      assert.equals(5, r)
      assert.equals(5, t)
      assert.equals(5, b)
    end)
    it("can unpack nil", function()
      local l, r, t, b = addon:UnpackLRTB()
      assert.equals(0, l)
      assert.equals(0, r)
      assert.equals(0, t)
      assert.equals(0, b)
    end)
  end)

  describe("XY", function()
    it("can unpack named values", function()
      local xy = { x = 10.0, y = 20.0 }
      local x, y = addon:UnpackXY(xy)
      assert.equals(xy.x, x)
      assert.equals(xy.y, y)
    end)
    it("can unpack missing named values", function()
      local xy = { y = 20.0 }
      local x, y = addon:UnpackXY(xy)
      assert.equals(0.0, x)
      assert.equals(xy.y, y)
    end)
    it("can unpack array values", function()
      local xy = { 10.0, 20.0 }
      local x, y = addon:UnpackXY(xy)
      assert.equals(xy[1], x)
      assert.equals(xy[2], y)
    end)
    it("can unpack missing array values", function()
      local xy = { 10.0 }
      local x, y = addon:UnpackXY(xy)
      assert.equals(xy[1], x)
      assert.equals(0.0, y)
    end)
    it("can unpack a number", function()
      local x, y = addon:UnpackXY(5)
      assert.equals(5, x)
      assert.equals(5, y)
    end)
    it("can unpack nil", function()
      local x, y = addon:UnpackXY()
      assert.equals(0.0, x)
      assert.equals(0.0, y)
    end)
  end)

  describe("Types", function()
    local testCases = {
      { "5", "string", "5" },
      { 0, "number", 0 },
      { false, "boolean", false },
      { "-5.62", "number", -5.62 },
      { "true", "boolean", true },
      { "false", "boolean", false },
      { -5.62, "string", "-5.62" },
      { 1, "boolean", true },
      { 0, "boolean", false },
      { true, "string", "true" },
      { false, "string", "false" },
      { true, "number", 1 },
      { false, "number", 0 },
    }
    for _, tc in ipairs(testCases) do
      it("can convert "..type(tc[1]).." to "..tc[2], function()
        local input, toType, expected = tc[1], tc[2], tc[3]
        local output = addon:ConvertValue(input, toType)
        assert.equals(expected, output)
      end)
    end
  end)
end)