local _, addon = ...
local PlaySoundFile = addon.G.PlaySoundFile

local sounds = {
  ["QuestAccepted"] = {
    fileId = 567400,
    path = "sound/interface/iquestactivate.ogg",
  },
  ["QuestAbandoned"] = {
    fileId = 567459,
    path = "sound/interface/igquestfailed.ogg"
  },
  ["BookOpen"] = {
    fileId = 567504,
    path = "sound/interface/iquestlogopena.ogg"
  },
  ["BookClose"] = {
    fileId = 567508,
    path = "sound/interface/iquestlogclosea.ogg"
  },
  ["BookWrite"] = {
    fileId = 567396,
    path = "sound/interface/writequestc.ogg"
  }
}

function addon:PlaySound(name)
  local sound = sounds[name]
  if not sound then
    addon.Logger:Warn("No sound registered with name:", name)
    return
  end

  PlaySoundFile(sound.path)
end