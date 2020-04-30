local _, addon = ...
addon:traceFile("DemoQuestData.lua")

addon.DemoQuestData = {
  {
    id = "dkill-ally",
    name = "Babby's First Quest",
    level = 5,
    objectives = {
      "kill 2 u='Mangy Wolf'",
      "kill 3 u=Chicken"
    }
  },
  {
    id = "dkill-horde",
    name = "Grob Has a Queue",
    level = 8,
    objectives = {
      "kill 3 u='Bloodtalon Scythemaw'",
      "kill 3 u='Elder Mottled Boar'",
    }
  },
  {
    id = "demote-horde",
    name = "Dancin' is my to do",
    level = 1,
    objectives = {
      "EMOTE em=dance",
      "EMOTE em=hug u=Chepi",
      "EMOTE em=salute u='Officer Thunderstrider'",
      "EMOTE em=roar u='Bluffwatcher' g=2",
    }
  },
  {
    id = "dtalk-ally",
    name = "Talkin' to the Squad",
    objectives = {
      "talkto u='Brog Hamfist'",
      "talkto u='Innkeeper Farley'",
      "talkto u='William Pestle'",
      "talkto 3 u=\"Stormwind Guard\""
    }
  },
  {
    id = "dtalk-horde",
    name = "Tbluff Getaway",
    objectives = {
      "TalkTo u=Bulrug",
      "TalkTo u=\"Jyn Stonehoof\"",
      "TalkTo u=Atepa",
      "TalkTo 3 u=Bluffwatcher"
    }
  }
}
