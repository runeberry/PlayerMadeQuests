local _, addon = ...
addon:traceFile("DemoQuestDB.lua")

addon.DemoQuestDB = {
  {
    id = "dkill-ally",
    name = "Babby's First Quest",
    script =
[[quest description="This is the first Player-Made Quest that I ever wrote. Surely this will go down in history!"
objective kill 2 t='Mangy Wolf'
objective kill 3 t=Chicken]]
  },
  {
    id = "dkill-horde",
    name = "Grob has a Queue",
    script =
[[quest d="Did you know that you can put quest descriptions in your script like this? Pretty neat, huh?"
obj kill 3 target='Bloodtalon Scythemaw'
obj kill 3 tar='Elder Mottled Boar']]
  },
  {
    id = "demote-horde",
    name = "Dancin' is my to do",
    script =
[[quest d="Get up on the floor\nDancin' all night long\nGet up on the floor\nDancin' til the break of dawn"
o EMOTE em=dance
o EMOTE em=hug t=Chepi
o EMOTE em=salute t='Officer Thunderstrider'
o EMOTE em=roar t='Bluffwatcher' g=2]]
  },
  {
    id = "dtalk-ally",
    name = "Talkin' to the Squad",
    script =
[[obj talkto t='Brog Hamfist'
obj talkto t='Innkeeper Farley'
obj talkto t='William Pestle'
obj talkto 2 t="Stormwind Guard"]]
  },
  {
    id = "dtalk-horde",
    name = "Tbluff Getaway",
    script =
[[obj TalkTo t=Bulrug
obj TalkTo t="Jyn Stonehoof"
obj TalkTo t=Atepa
obj TalkTo 3 t=Bluffwatcher]]
  },
  {
    id = "ss",
    name = "Southshore Showdown",
    script =
[[obj talkto t="Barkeep Kelly"
obj talkto t="Innkeeper Anderson"
obj talkto t="Wesley"]]
  }
}