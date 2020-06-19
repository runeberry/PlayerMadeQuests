local mock = require("spec/mock")

local deps = {}

local function newFrameMock()
  return {
    SetFrameStrata = mock:NewMock(),
    Show = mock:NewMock(),
    Hide = mock:NewMock(),
    SetScript = mock:NewMock(),
  }
end

local function newAceFrameMock()
  local aceFrameMock = {
    frame = newFrameMock(),
    SetTitle = mock:NewMock(),
    SetStatusText = mock:NewMock(),
    SetCallback = mock:NewMock(),
    SetLayout = mock:NewMock(),
    EnableButtonTooltips = mock:NewMock(),
    SetTree = mock:NewMock(),
    AddChild = mock:NewMock(),
    SelectByValue = mock:NewMock(),
    SetFullWidth = mock:NewMock(),
    SetFullHeight = mock:NewMock(),
    SetStatusTable = mock:NewMock(),
  }

  aceFrameMock.content = { obj = aceFrameMock }

  return aceFrameMock
end

function deps:Init(addon)
  addon.SILENT_PRINT = false
  addon.Ace = {
    _stable = {},
    RegisterEvent = mock:NewMock(),
    RegisterComm = mock:NewMock(),
    ScheduleTimer = function(self, func, delay, ...)
      addon:AddTimerFunction(func, ...)
    end,
    ScheduleRepeatingTimer = mock:NewMock( mock:Returns(1) ), -- todo: Create a mock implementation of this
    CancelTimer = mock:NewMock(), -- todo: Create a mock implementation of this
    Serialize = function(self, t)
      local serialized = addon:CreateID("serialize-mock-%i")
      self._stable[serialized] = addon:CopyTable(t)
      return serialized
    end,
    Deserialize = function(self, serialized)
      return true, self._stable[serialized] or error("Serialized value not mocked: "..serialized)
    end
  }
  addon.AceGUI = {
    Create = mock:NewMock( mock:Returns(newAceFrameMock()) )
  }
  addon.LibCompress = {
    _ctable = {},
    CompressHuffman = function(self, str)
      local compressed = addon:CreateID("compress-mock-%i")
      self._ctable[compressed] = str
      return compressed
    end,
    Decompress = function(self, compressed)
      return self._ctable[compressed] or error("Compressed value not mocked: "..compressed)
    end,
    GetAddonEncodeTable = mock:NewMock()
  }
  addon.LibScrollingTable = {}

  addon.G = {
    print = mock:NewMock("print", mock:Handler(function(...)
      if addon.SILENT_PRINT then return end
      local args, spaced = table.pack(...), {}
      for i = 1, args.n do
        local arg = args[i]
        if arg == nil then
          table.insert(spaced, "nil")
        elseif type(arg) == "string" then
          table.insert(spaced, arg)
        else
          table.insert(spaced, tostring(arg))
        end
        table.insert(spaced, " ")
      end
      table.insert(spaced, "\n")
      io.write(table.unpack(spaced))
    end) ),
    strjoin = function(delim, ...) return table.concat({ ... }, delim) end,
    -- Adapted from: https://gist.github.com/jaredallard/ddb152179831dd23b230
    strsplit = function(delim, str)
      local result = { }
      local from  = 1
      local delim_from, delim_to = string.find( str, delim, from  )
      while delim_from do
        table.insert( result, string.sub( str, from , delim_from-1 ) )
        from  = delim_to + 1
        delim_from, delim_to = string.find( str, delim, from  )
      end
      table.insert( result, string.sub( str, from  ) )
      return table.unpack(result)
    end,
    time = function() return math.floor(os.clock() * 1000) end,
    unpack = table.unpack,

    CombatLogGetCurrentEventInfo = mock:NewMock(),
    CreateFrame = mock:NewMock( mock:Returns({}) ),
    GetBestMapForUnit = mock:NewMock( mock:Returns({}) ),
    GetMapInfo = mock:NewMock( mock:Returns({}) ),
    GetPlayerMapPosition = mock:NewMock( mock:Returns({}) ),
    GetUnitName = mock:NewMock( mock:Returns("name") ),
    GetRealZoneText = mock:NewMock( mock:Returns("zone") ),
    GetSubZoneText = mock:NewMock( mock:Returns("subzone") ),
    GetZoneText = mock:NewMock( mock:Returns("zone") ),
    PlaySoundFile = mock:NewMock(),
    SlashCmdList = {},
    StaticPopupDialogs = {},
    StaticPopup_Show = mock:NewMock(),
    StaticPopup_Hide = mock:NewMock(),
    UnitExists = mock:NewMock( mock:Returns(false) ),
    UnitGUID = mock:NewMock( mock:Returns("guid") ),
    UnitIsFriend = mock:NewMock( mock:Returns(false) ),
    UIErrorsFrame = {},
    UIParent = {},
    UISpecialFrames = {},
  }
end

return deps