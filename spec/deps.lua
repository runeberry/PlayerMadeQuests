local mock = require("spec/mock")

local deps = {}

-- Lazy shortcut for writing a function with static returns
local function ret(...)
  local args = { ... }
  if #args == 0 then
    return function() return end
  else
    return function() return table.unpack(args) end
  end
end

local function newFrameMock()
  return {
    SetFrameStrata = ret(),
    Show = ret(),
    Hide = ret(),
    SetScript = ret(),
  }
end

local function newAceFrameMock()
  local aceFrameMock = {
    frame = newFrameMock(),
    SetTitle = ret(),
    SetStatusText = ret(),
    SetCallback = ret(),
    SetLayout = ret(),
    EnableButtonTooltips = ret(),
    SetTree = ret(),
    AddChild = ret(),
    SelectByValue = ret(),
    SetFullWidth = ret(),
    SetFullHeight = ret(),
    SetStatusTable = ret(),
  }

  aceFrameMock.content = { obj = aceFrameMock }

  return aceFrameMock
end

function deps:Init(addon)
  addon.Ace = mock:NewMock({
    _stable = {},
    RegisterEvent = ret(),
    RegisterComm = ret(),
    ScheduleTimer = function(self, func, delay, ...)
      addon:AddTimerFunction(func, ...)
    end,
    ScheduleRepeatingTimer = ret(1), -- Create a mock implementation of this if needed
    CancelTimer = ret(), -- Create a mock implementation of this if needed
    Serialize = function(self, t)
      local serialized = addon:CreateID("serialize-mock-%i")
      self._stable[serialized] = addon:CopyTable(t)
      return serialized
    end,
    Deserialize = function(self, serialized)
      return true, self._stable[serialized] or error("Serialized value not mocked: "..serialized)
    end
  })
  addon.AceGUI = mock:NewMock({
    Create = function() return newAceFrameMock() end,
  })
  addon.LibCompress = mock:NewMock({
    _ctable = {},
    _hashCounter = 0,
    CompressHuffman = function(self, str)
      local compressed = addon:CreateID("compress-mock-%i")
      self._ctable[compressed] = str
      return compressed
    end,
    Decompress = function(self, compressed)
      return self._ctable[compressed] or error("Compressed value not mocked: "..compressed)
    end,
    GetAddonEncodeTable = function()
      return {
        _entable = {},
        Encode = function(self, str)
          local encoded = addon:CreateID("encode-mock-%i")
          self._entable[encoded] = str
          return encoded
        end,
        Decode = function(self, encoded)
          return self._entable[encoded] or error("Encoded value not mocked: "..encoded)
        end,
      }
    end,
    fcs32init = function(self)
      self._hashCounter = self._hashCounter + 1
      return self._hashCounter
    end,
    fcs32update = function(self)
      self._hashCounter = self._hashCounter + 1
      return self._hashCounter
    end,
    fcs32final = function(self)
      self._hashCounter = self._hashCounter + 1
      return self._hashCounter
    end,
  })
  addon.LibScrollingTable = mock:NewMock({})

  addon.G = mock:NewMock({
    date = ret("01/01/2000"),
    print = function(...)
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
    end,
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
    unpack = function(...) return table.unpack(...) end,

    AddMessageEventFilter = ret(),
    CombatLogGetCurrentEventInfo = ret(),
    CheckInteractDistance = ret(),
    CreateFrame = function() return {} end,
    GameTooltip = {}, -- todo: mock out tooltip methods
    GetBestMapForUnit = ret(),
    GetBuildInfo = ret("1.2.3", "10203", "Jan 1, 2000", 10203),
    GetCoinTextureString = ret("money"),
    GetGuildInfo = ret(),
    GetMapInfo = ret(),
    GetPlayerMapPosition = ret(),
    GetUnitName = function(uid)
      -- Player name should always return even if mock env is reset
      if uid == "player" then
        return "PlayerName"
      end
    end,
    GetRealZoneText = ret(),
    GetSubZoneText = ret(),
    GetMinimapZoneText = ret(),
    GetZoneText = ret(),
    GetItemInfo = ret(),
    GetItemInfoInstant = ret(),
    GetContainerItemInfo = ret(),
    GetInventorySlotInfo = ret(),
    GetInventoryItemID = ret(),
    IsEquippedItem = ret(),
    IsInGroup = ret(),
    IsInGuild = ret(),
    IsInRaid = ret(),
    PlaySoundFile = ret(),
    ReloadUI = ret(),
    SlashCmdList = {},
    StaticPopupDialogs = {},
    StaticPopup_Show = ret(),
    StaticPopup_Hide = ret(),
    UnitAura = ret(),
    UnitClass = ret(),
    UnitExists = ret(),
    UnitFactionGroup = ret(),
    UnitFullName = ret("PlayerName", "PlayerRealm"),
    UnitGUID = ret(),
    UnitIsFriend = ret(),
    UnitIsPlayer = ret(),
    UnitLevel = ret(),
    UnitRace = ret(),
    UnitSex = ret(),
    UIErrorsFrame = {
      AddMessage = ret(),
    },
    UIParent = {},
    UISpecialFrames = {},

    SetItemButtonCount = ret(),
    SetItemButtonStock = ret(),
    SetItemButtonTexture = ret(),
    SetItemButtonTextureVertexColor = ret(),
    SetItemButtonDesaturated = ret(),
    SetItemButtonNormalTextureVertexColor = ret(),
    SetItemButtonNameFrameVertexColor = ret(),
    SetItemButtonSlotVertexColor = ret(),
    SetItemButtonQuality = ret(),
    HandleModifiedItemClick = ret(),
  })
end

return deps