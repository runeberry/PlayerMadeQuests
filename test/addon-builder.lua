local deps = require("deps")

local builder = {}
local SRC_DIR = "../src/"

local function getIncludedFilesFromXML(xmlFilename, list, circ)
  xmlFilename = SRC_DIR..xmlFilename
  list = list or {}
  circ = circ or {}
  if circ[xmlFilename] then
    error("Circular reference detected: "..xmlFilename)
  end
  circ[xmlFilename] = true

  for line in io.lines(xmlFilename) do
    local includedFilename = line:match('file="([^"]+)')
    if includedFilename then
      if includedFilename:match(".xml$") then
        getIncludedFilesFromXML(includedFilename, list, circ)
      elseif includedFilename:match(".lua$") then
        if list[includedFilename] then
          error("File included more than once: "..includedFilename)
        end
        table.insert(list, SRC_DIR..includedFilename)
      else
        error("Unrecognized file type: "..includedFilename)
      end
    end
  end

  return list
end

-- These additional functions are appended to the addon object
-- when it is created
local testMethods = {
  ["AddTimerFunction"] = function(self, fn, ...)
    if not self.timerFunctions then self.timerFunctions = {} end
    local params = { ... }
    table.insert(self.timerFunctions, function()
      fn(table.unpack(params))
    end)
  end,
  ["Advance"] = function(self)
    if not self.timerFunctions then return end
    for _, func in pairs(self.timerFunctions) do
      local ok, err = pcall(func)
      if not ok then
        print("Error on timer function:", err)
      end
    end
    self.timerFunctions = nil
  end,
  ["Init"] = function(self)
    self.Ace:OnInitialize()
  end
}

function builder:Build(opts)
  local requires = getIncludedFilesFromXML("index.xml")

  local addon = {
    LOG_LEVEL = 2, -- Only log errors by default
    LOG_MODE = "simple"
  }

  if opts then
    addon.LOG_LEVEL = opts.LOG_LEVEL or addon.LOG_LEVEL
    addon.LOG_MODE = opts.LOG_MODE or addon.LOG_MODE
  end

  for name, fn in pairs(testMethods) do
    addon[name] = fn
  end

  deps:Init(addon)

  for _, req in pairs(requires) do
    -- print(req)
    assert(loadfile(req))(nil, addon)
  end

  return addon
end

return builder