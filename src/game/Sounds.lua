local _, addon = ...
local PlaySoundFile = addon.G.PlaySoundFile

local sounds = {
  ["QuestAccepted"] = {
    fileId = 567400,
    path = "sound/interface/iquestactivate.ogg",
    events = { "QuestStarted" },
  },
  ["QuestAbandoned"] = {
    fileId = 567459,
    path = "sound/interface/igquestfailed.ogg",
    events = { "QuestAbandoned" },
  },
  ["QuestCompleted"] = {
    fileId = 567439,
    path = "sound/interface/iquestcomplete.ogg",
    events = { "QuestCompleted" },
  },
  ["BookOpen"] = {
    fileId = 567504,
    path = "sound/interface/iquestlogopena.ogg",
  },
  ["BookClose"] = {
    fileId = 567508,
    path = "sound/interface/iquestlogclosea.ogg",
  },
  ["BookWrite"] = {
    fileId = 567396,
    path = "sound/interface/writequestc.ogg",
  },
  ["CloseWindow"] = {
    fileId = 567407,
    path = "sound/interface/uchatscrollbutton.ogg",
  }
}

function addon:PlaySound(name)
  local sound = sounds[name]
  if not sound then
    addon.Logger:Warn("No sound registered with name: %s", name)
    return
  end

  PlaySoundFile(sound.path)
end

-- Any sounds with "events" attached will automatically be triggered when those AppEvents are fired
addon:OnBackendReady(function()
  for id, sound in pairs(sounds) do
    if sound.events then
      for _, event in pairs(sound.events) do
        addon.AppEvents:Subscribe(event, function()
          addon:PlaySound(id)
        end)
      end
    end
  end
end)