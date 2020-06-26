local _, addon = ...
addon:traceFile("DemoQuestDB.lua")

local descriptions = {
  ["kill"] = [[This demonstrates how to write a quest to kill enemies. The target's name must be spelled and capitalized exactly right, otherwise you won't gain quest progress for killing them!

Also, if the target's name is more than one word, you must surround it with quotes. Otherwise, quotes are optional.

]],
  ["talkto"] = [[This demonstrates how to write a quest to talk to certains NPCs. The target's name must be spelled and capitalized exactly right, and quotes must be used if the target's name is more than one word.

If you specify a goal number, you must talk to that many different NPCs with the same name. Talking to the same NPC twice won't grant additional quest progress!

]],
  ["emote"] = [[This demonstrates how to write a quest to use certain in-game emotes. You can specify a target that the emote must be used with. If you don't specify a target, then performing the emote anywhere will count.

Just like with the 'talkto' objective, if you specify a goal number, you must use that emote on multiple different NPCs with that same name.

]],
  ["explore"] = [[This demonstrates how to write a quest to visit certain locations. You must specify a zone, but you can also specify a subzone or coordinates for a more precise destination.

]]
}

addon.DemoQuestDB = {
  {
    id = "tutorial-kill-ally",
    order = 1,
    parameters = {
      name = "Objective: Kill X (Alliance)",
      description = descriptions["kill"].."These devious foes can be found around the farms directly south of Stormwind.",
    },
    script = [[
objectives:
  - kill Cow
  - kill 3 Chicken
  - kill 5 "Mangy Wolf"]]
  },
  {
    id = "tutorial-kill-horde",
    order = 2,
    parameters = {
      name = "Objective: Kill X (Horde)",
      description = descriptions["kill"].."These fiendish beasts can be found at or east of Jaggedswine Farm, just outside of Orgrimmar.",
    },
    script = [[
objectives:
  - kill 'Bloodtalon Scythemaw'
  - kill 3 Swine
  - kill 5 'Elder Mottled Boar']]
  },
  {
    id = "tutorial-talkto-ally",
    order = 3,
    parameters = {
      name = "Objective: Talk to NPC (Alliance)",
      description = descriptions["talkto"].."These fine folks can be found in Goldshire, south of Stormwind.",
    },
    script = [[
objectives:
  - talkto 'Brog Hamfist'
  - talkto 'Innkeeper Farley'
  - talkto 2 "Stormwind Guard"]]
  },
  {
    id = "tutorial-talkto-horde",
    order = 4,
    parameters = {
      name = "Objective: Talk to NPC (Horde)",
      description = descriptions["talkto"].."These upstanding citizens can be found at the zeppelin tower outside of Orgrimmar.",
    },
    script = [[
objectives:
  - talkto Frezza
  - talkto "Snurk Bucksquick"
  - talkto 2 "Orgrimmar Grunt"]]
  },
  {
    id = "tutorial-emote-ally",
    order = 5,
    parameters = {
      name = "Objective: Use emote (Alliance)",
      description = descriptions["emote"].."These eager participants are waiting for you in Goldshire, south of Stormwind",
    },
    script = [[
objectives:
  - emote roar
  - emote cry Tomas
  - emote fart 2 "Stormwind Guard"]]
  },
  {
    id = "tutorial-emote-horde",
    order = 6,
    parameters = {
      name = "Objective: Use emote (Horde)",
      description = descriptions["emote"].."These willing volunteers can be found in or around the Orgrimmar inn.",
    },
    script = [[
objectives:
  - emote dance
  - emote clap Sarok
  - emote smile Kozish
  - emote salute 2 "Orgrimmar Grunt"]]
  },
  {
    id = "tutorial-explore-ally",
    order = 7,
    parameters = {
      name = "Objective: Explore (Alliance)",
      description = descriptions["explore"].."These locations are around Goldshire, south of Stormwind."
    },
    script = [[
objectives:
  - explore "Elwynn Forest"
  - explore "Elwynn Forest" 40.2 74.6
  - explore:
      zone: "Elwynn Forest"
      subzone: "Lion's Pride Inn"
  - explore:
      zone: "Elwynn Forest"
      subzone: "Goldshire"
      posx: 39.5
      posy: 64.5]]
  },
  {
    id = "tutorial-explore-horde",
    order = 8,
    parameters = {
      name = "Objective: Explore (Horde)",
      description = descriptions["explore"].."These locations are in northern Durotar, just outside of Orgrimmar."
    },
    script = [[
objectives:
  - explore Durotar
  - explore Durotar 48 12.2
  - explore:
      zone: Durotar
      subzone: "Skull Rock"
  - explore:
      zone: Durotar
      subzone: "Jaggedswine Farm"
      posx: 48.7
      posy: 17.2]]
  }
}