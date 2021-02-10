local addon = require("spec/addon-builder"):Build()

local defaultFlexSpace = 1000

describe("Flex", function()
  local testCases = {
    {
      testName = "can calculate flex size",
      flexParams = {
        { flex = 3 },
        { flex = 3 },
        { flex = 4 },
      },
      expected = { 300, 300, 400 },
    },
    {
      testName = "can implicitly define flex size of 1 (single unit)",
      flexParams = {
        { },
        { flex = 3 },
      },
      expected = { 250, 750 },
    },
    {
      testName = "can implicitly define flex size of 1 (both units)",
      flexParams = {
        { },
        { },
      },
      expected = { 500, 500 },
    },
    {
      testName = "can account for fixed width (first)",
      flexParams = {
        { size = 180 },
        { flex = 3 },
        { flex = 2 },
      },
      expected = { 180, 492, 328 },
    },
    {
      testName = "can account for fixed width (middle)",
      flexParams = {
        { flex = 3 },
        { size = 180 },
        { flex = 2 },
      },
      expected = { 492, 180, 328 },
    },
    {
      testName = "can account for fixed width (last)",
      flexParams = {
        { flex = 3 },
        { flex = 2 },
        { size = 180 },
      },
      expected = { 492, 328, 180 },
    },
    {
      testName = "can respect min bound",
      flexParams = {
        { flex = 3 },
        { flex = 3, min = 600 },
        { flex = 2 },
      },
      expected = { 240, 600, 160 },
    },
    {
      testName = "can respect max bound",
      flexParams = {
        { flex = 3 },
        { flex = 3, max = 200 },
        { flex = 2 },
      },
      expected = { 480, 200, 320 },
    },
  }

  for i, tc in ipairs(testCases) do
    it(tc.testName, function()
      local results = addon:CalculateFlex(tc.flexSpace or defaultFlexSpace, tc.flexParams)
      assert.same(tc.expected, results)
    end)
  end

end)