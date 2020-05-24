local mock = require("spec/mock")

local deps = {}

function deps:Init(addon)
  addon.Ace = {
    RegisterEvent = mock:NewMock(),
    ScheduleTimer = function(self, func, delay, ...)
      addon:AddTimerFunction(func, ...)
    end
  }
  addon.AceGUI = {
    Create = mock:NewMock( mock:Returns({
      frame = {
        SetFrameStrata = mock:NewMock()
      },
      content = {},
      SetTitle = mock:NewMock(),
      SetStatusText = mock:NewMock(),
      SetCallback = mock:NewMock(),
      SetLayout = mock:NewMock(),
      EnableButtonTooltips = mock:NewMock(),
      SetTree = mock:NewMock(),
      AddChild = mock:NewMock(),
      SelectByValue = mock:NewMock()
    }) )
  }
  addon.LibCompress = {}
  addon.LibScrollingTable = {}

  addon.G = {
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
    time = function() return os.clock() * 1000 end,
    unpack = table.unpack,

    CombatLogGetCurrentEventInfo = mock:NewMock(),
    CreateFrame = mock:NewMock( mock:Returns({}) ),
    GetUnitName = mock:NewMock( mock:Returns("name") ),
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