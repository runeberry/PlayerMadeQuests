local _, addon = ...
addon:traceFile("DemoQuestData.lua")

addon.DemoQuestData = {
  {
    id = "dkill-ally",
    name = "Babby's First Quest",
    level = 5,
    objectives = {
      "Kill [2] 'Mangy Wolf'",
      "Kill [3] 'Chicken'"
    }
  },
  {
    id = "dkill-horde",
    name = "Grob Has a Queue",
    level = 8,
    objectives = {
      "Kill [3] 'Bloodtalon Scythemaw'",
      "Kill [3] 'Elder Mottled Boar'",
    }
  },
  {
    id = "dtalk-ally",
    name = "Talkin' to the Squad",
    objectives = {
      "TalkTo 'Brog Hamfist'",
      "TalkTo 'Innkeeper Farley'",
      "TalkTo 'William Pestle'",
      "TalkTo [3] \"Stormwind Guard\""
    }
  },
  {
    id = "dtalk-horde",
    name = "Tbluff Getaway",
    objectives = {
      "TalkTo Bulrug",
      "TalkTo \"Jyn Stonehoof\"",
      "TalkTo Atepa",
      "TalkTo [3] Bluffwatcher"
    }
  }
}
