local addon = require("spec/addon-builder"):Build()

describe("Strings", function()
  describe("Colorize", function()
    local str = "test string"
    it("can colorize with named color", function()
      local colorized = addon:Colorize("red", str)
      assert.not_equals(str, colorized)
    end)
    it("can colorize with custom color", function()
      local colorized = addon:Colorize("|cffaf9023", str)
      assert.not_equals(str, colorized)
    end)
    it("can colorize default", function()
      local colorized = addon:Colorize(nil, str)
      assert.not_equals(str, colorized)
    end)
  end)
  describe("strmod", function()
    local i
    local val1, val2 = "extra", "stuff"
    local testCases = {
      {
        desc = "can mod at beginning of string",
        str = "fieldname: parameter: context:",
        pattern = "^%S-:",
        expected = "1: parameter: context:",
        mod = function(s)
          i = i + 1
          return i..":"
        end
      },
      {
        desc = "can mod at end of string",
        str = "fieldname: # This is a comment",
        pattern = "#.-$",
        expected = "fieldname: ##1##",
        mod = function(s)
          i = i + 1
          return "##"..i.."##"
        end
      },
      {
        desc = "can mod multiline strings",
        str = [[
Line A
Line B


Line C]],
        pattern = "\n",
        expected = "Line A1Line B234Line C",
        mod = function(s)
          i = i + 1
          return tostring(i)
        end
      },
      {
        desc = "can mod in a shorter string",
        str = "Phrase A, phrase B, phrase C",
        pattern = "[Pp]hrase ",
        expected = "PA, pB, pC",
        mod = function(s)
          return s:sub(1, 1)
        end
      },
      {
        desc = "can mod in a longer string",
        str = "Phrase A, phrase B, phrase C",
        pattern = "[Pp]hrase",
        expected = "PhrasePhrase A, phrasephrase B, phrasephrase C",
        mod = function(s)
          return s..s
        end
      },
      {
        desc = "can pass parameters through varargs",
        str = "The varargs values are: ",
        pattern = ": ",
        expected = "The varargs values are: "..val1..val2,
        mod = function(s, v1, v2)
          return s..v1..v2
        end
      },
      {
        desc = "can convert non-string values",
        str = "The number is (secret)",
        pattern = "%(secret%)",
        expected = "The number is 42",
        mod = function(s)
          return 42
        end
      },
      {
        desc = "can convert nil to empty string",
        str = "Remove <this> piece!",
        pattern = "<this>",
        expected = "Remove  piece!",
        mod = function(s)
          return nil
        end
      }
    }
    before_each(function()
      i = 0
    end)
    for _, tc in ipairs(testCases) do
      it(tc.desc, function()
        local actual = addon:strmod(tc.str, tc.pattern, tc.mod, val1, val2)
        assert.equals(tc.expected, actual)
      end)
    end
  end)
  describe("ParseCoords", function()
    local testCases = {
      { str = "38,22", expected = { 38, 22 } },
      { str = "    38.14  ,    22.78     ", expected = { 38.14, 22.78 } },
      { str = "38.1, 22.7, 0.8", expected = { 38.1, 22.7, 0.8 } },
      { str = "one,two", err = true },
      { str = "38", err = true },
      { str = "38,22.7,0.84,11", err = true },
      { str = 38.7, err = true },
      { str = nil, err = true },
      { str = "", err = true },
      { str = "one,two", err = true },
      { str = "38 . 14 , 22. 78", err = true },
    }
    for i, tc in ipairs(testCases) do
      if tc.expected then
        it("can parse coordinates "..addon:Enquote(i, "()"), function()
          assert.same(tc.expected, { addon:ParseCoords(tc.str) })
        end)
      elseif tc.err then
        it("can reject bad input "..addon:Enquote(i, "()"), function()
          assert.has_error(function() addon:ParseCoords(tc.str) end)
        end)
      end
    end
  end)
end)