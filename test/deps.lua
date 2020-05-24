local deps = {}

local function setReturns(...)
  local ret = { ... }
  return function()
    return table.unpack(ret)
  end
end

function deps:Init(addon)
  addon.Ace = {
    RegisterEvent = setReturns(),
    ScheduleTimer = function(self, func, delay, ...)
      addon:AddTimerFunction(func, ...)
    end
  }
  addon.AceGUI = {}
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

    CombatLogGetCurrentEventInfo = setReturns(),
    CreateFrame = setReturns({}),
    GetUnitName = setReturns("name"),
    PlaySoundFile = setReturns(),
    SlashCmdList = {},
    StaticPopupDialogs = {},
    StaticPopup_Show = setReturns(),
    StaticPopup_Hide = setReturns(),
    UnitExists = setReturns(false),
    UnitGUID = setReturns("guid"),
    UnitIsFriend = setReturns(false),
    UIErrorsFrame = {},
    UIParent = {},
    UISpecialFrames = {},
  }
end

return deps