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
    }
  end)

  describe("tlen", function()
    it("can return table length", function()
      assert.equals(3, addon:tlen(t.table))
      assert.equals(3, addon:tlen(t.array))
      assert.equals(3, addon:tlen(t.set))
      assert.equals(8, addon:tlen(t))
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
    it("can merge nested array of matching length", function()
      local patch = {
        array = {
          [1] = { name = "another name" },
          [3] = { value = 300 }
        }
      }

      local expected = addon:CopyTable(t.array)
      expected[1].name = patch.array[1].name
      expected[3].value = patch.array[3].value

      local merged = addon:MergeTable(t, patch)

      assert.same(expected, merged.array)
    end)
    it("can merge nested array with additional items", function()
      local patch = {
        array = {
          { name = "arrayItem1", val = 1 },
          { name = "arrayItem2", val = 2 },
          { name = "arrayItem3", val = 3 },
          { name = "arrayItem4", val = 4 },
          { name = "arrayItem5", val = 5 },
        }
      }

      local expected = addon:CopyTable(t)
      expected.array = patch.array

      local merged = addon:MergeTable(t, patch)

      assert.same(expected.array, merged.array)
    end)
    it("cannot merge nil tables", function()
      assert.has_error(function() addon:MergeTable(nil, { rootName = "new name" }) end)
      assert.has_error(function() addon:MergeTable(t, nil) end)
      assert.has_error(function() addon:MergeTable(nil,nil) end)
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