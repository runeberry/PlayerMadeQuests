local _, addon = ...
addon:traceFile("DemoQuestData.lua")

addon.DemoQuestData = {
  {
    id = "dkill-ally",
    script = [[
      quest "Babby's First Quest"
      objective kill 2 t='Mangy Wolf'
      objective kill 3 t=Chicken
    ]]
  },
  {
    id = "dkill-horde",
    script = [[
      quest name="Grob has a Queue"
      obj kill 3 target='Bloodtalon Scythemaw'
      obj kill 3 tar='Elder Mottled Boar'
    ]]
  },
  {
    id = "demote-horde",
    script = [[
      q n="Dancin' is my to do"
      o EMOTE em=dance
      o EMOTE em=hug t=Chepi
      o EMOTE em=salute t='Officer Thunderstrider'
      o EMOTE em=roar t='Bluffwatcher' g=2
    ]]
  },
  {
    id = "dtalk-ally",
    script = [[
      quest name='Talkin\' to the Squad'
      obj talkto t='Brog Hamfist'
      obj talkto t='Innkeeper Farley'
      obj talkto t='William Pestle'
      obj talkto 3 t="Stormwind Guard"
    ]]
  },
  {
    id = "dtalk-horde",
    script = [[
      q "Tbluff Getaway"
      obj TalkTo t=Bulrug
      obj TalkTo t="Jyn Stonehoof"
      obj TalkTo t=Atepa
      obj TalkTo 3 t=Bluffwatcher
    ]]
  }
}
