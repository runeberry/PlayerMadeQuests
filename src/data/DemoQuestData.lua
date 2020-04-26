local _, addon = ...
addon:traceFile("DemoQuestData.lua")

addon.DemoQuestData = {
  {
    id = "demo1",
    name = "Babby's First Quest",
    author = "Nekrage-Grobbulus",
    objectives = {
      "TargetMob,0,5,Cow",
      "KillMob,0,2,Mangy Wolf",
      "KillMob,0,3,Chicken"
    }
  },
  {
    id = "demo2",
    name = "STONKS",
    author = "Nekrage-Grobbulus",
    objectives = {
      "KillMob,0,3,Defias Prisoner",
      "KillMob,0,3,Defias Inmate",
      "KillMob,0,3,Defias Captive"
    }
  },
  {
    id = "demo3",
    name = "Grob Has a Queue",
    author = "Midna-Kirtonos",
    objectives = {
      "KillMob,0,2,Bloodtalon Scythemaw",
      "KillMob,0,3,Elder Mottled Boar",
      "TargetMob,0,5,Venomtail Scorpid"
    }
  },
  {
    id = "demo4",
    name = "More Blood for de Blood God",
    author = "Midna-Kirtonos",
    objectives = {
      "KillMob,0,3,Bloodscalp Axe Thrower",
      "KillMob,0,2,Bloodscalp Shaman",
      "TargetMob,0,5,Black Kingsnake"
    }
  },
  {
    id = "demo5",
    name = "Killing Stuff is Hard",
    author = "Midna-Kirtonos",
    objectives = {
      "TargetMob,0,3,Bloodtalon Scythemaw",
      "TargetMob,0,3,Elder Mottled Boar",
      "TargetMob,0,3,Venomtail Scorpid"
    }
  },
  {
    id = "dtalk",
    name = "Talkin' to the Squad",
    author = "Nekrage-Grobbulus",
    objectives = {
      "TalkToNPC,0,1,Brog Hamfist",
      "TalkToNPC,0,1,Innkeeper Farley",
      "TalkToNPC,0,1,William Pestle",
      "TalkToNPC,0,1,Stormwind Guard"
    }
  }
}
