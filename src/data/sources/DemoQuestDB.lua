local _, addon = ...
addon:traceFile("DemoQuestDB.lua")

local descriptions = {
  ["kill"] = [[This demonstrates how to write a quest to kill enemies. The target's name must be spelled and capitalized exactly right, otherwise you won't gain quest progress for killing them!

Also, if the target's name is more than one word, you must surround it with quotes. Otherwise, quotes are optional.

]],
  ["talkto"] = [[This demonstrates how to write a quest to talk to certains NPCs. The target's name must be spelled and capitalized exactly right, and quotes must be used if the target's name is more than one word.

If you specify a goal number, you must talk to that many different NPCs with the same name. Talking to the same NPC twice won't grant additional quest progress!

]],
  ["emote"] = [[This demonstrats how to write a quest to use certain in-game emotes. You can specify a target that the emote must be used with. If you don't specify a target, then performing the emote anywhere will count.

Just like with the 'talkto' objective, if you specify a goal number, you must use that emote on multiple different NPCs with that same name.

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
    script =
[[objective kill t=Cow
objective kill 3 t=Chicken
objective kill 5 t="Mangy Wolf"]]
  },
  {
    id = "tutorial-kill-horde",
    order = 2,
    parameters = {
      name = "Objective: Kill X (Horde)",
      description = descriptions["kill"].."These fiendish beasts can be found at or east of Jaggedswine Farm, just outside of Orgrimmar.",
    },
    script =
[[objective kill t='Bloodtalon Scythemaw'
objective kill 3 t=Swine
objective kill 5 t='Elder Mottled Boar']]
  },
  {
    id = "tutorial-talkto-ally",
    order = 3,
    parameters = {
      name = "Objective: Talk to NPC (Alliance)",
      description = descriptions["talkto"].."These fine folks can be found in Goldshire, south of Stormwind.",
    },
    script =
[[obj talkto t='Brog Hamfist'
obj talkto t='William Pestle'
obj talkto 2 t="Stormwind Guard"]]
  },
  {
    id = "tutorial-talkto-horde",
    order = 4,
    parameters = {
      name = "Objective: Talk to NPC (Horde)",
      description = descriptions["talkto"].."These upstanding citizens can be found at the zeppelin tower outside of Orgrimmar.",
    },
    script =
[[obj talkto t=Frezza
obj talkto t="Snurk Bucksquick"
obj talkto 2 t="Orgrimmar Grunt"]]
  },
  {
    id = "tutorial-emote-ally",
    order = 5,
    parameters = {
      name = "Objective: Use emote (Alliance)",
      description = descriptions["emote"].."TODO: finish this description",
    },
    script =
[[obj emote em=roar]]
  },
  {
    id = "tutorial-emote-horde",
    order = 6,
    parameters = {
      name = "Objective: Use emote (Horde)",
      description = descriptions["emote"].."These willing volunteers can be found in or around the Orgrimmar inn.",
    },
    script =
[[obj emote em=dance
obj emote em=clap t=Sarok
obj emote em=smile t=Kozish
obj emote 2 em=salute t="Orgrimmar Grunt"]]
  },
}