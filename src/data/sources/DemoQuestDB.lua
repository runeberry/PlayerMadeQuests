local _, addon = ...

local factions = {
  Alliance = "Alliance",
  Horde = "Horde",
}

local helps = {
  kill = "This demonstrates how to write a quest to kill enemies. The target's name must be spelled and capitalized exactly right, otherwise you won't gain quest progress for killing them!\n\nAlso, if the target's name is more than one word, you must surround it with quotes. Otherwise, quotes are optional.",
  talkto = "This demonstrates how to write a quest to talk to certains NPCs. The target's name must be spelled and capitalized exactly right, and quotes must be used if the target's name is more than one word.\n\nIf you specify a goal number, you must talk to that many different NPCs with the same name. Talking to the same NPC twice won't grant additional quest progress!",
  emote = "This demonstrates how to write a quest to use certain in-game emotes. You can specify a target that the emote must be used with. If you don't specify a target, then performing the emote anywhere will count.\n\nJust like with the 'talkto' objective, if you specify a goal number, you must use that emote on multiple different NPCs with that same name.",
  explore = "This demonstrates how to write a quest to visit certain locations. You must specify a zone, but you can also specify a subzone or coordinates for a more precise destination."
}

addon.DemoQuestDB = {
  {
    demoId = "tutorial-kill-ally",
    demoName = "Objective: Kill X",
    helpText = helps.kill,
    faction = factions.Alliance,
    order = 1,
    script = [[
quest:
  name: 'Objective: Kill X'
  description: These devious foes can be found around the farms directly south of Stormwind.
objectives:
  - kill Cow
  - kill 3 Chicken
  - kill 5 "Mangy Wolf"]]
  },
  {
    demoId = "tutorial-kill-horde",
    demoName = "Objective: Kill X",
    helpText = helps.kill,
    faction = factions.Horde,
    order = 2,
    script = [[
quest:
  name: 'Objective: Kill X'
  description: These fiendish beasts can be found at or east of Jaggedswine Farm, just outside of Orgrimmar.
objectives:
  - kill 'Bloodtalon Scythemaw'
  - kill 3 Swine
  - kill 5 'Elder Mottled Boar']]
  },
  {
    demoId = "tutorial-talkto-ally",
    demoName = "Objective: Talk to NPC",
    helpText = helps.talkto,
    faction = factions.Alliance,
    order = 3,
    script = [[
quest:
  name: 'Objective: Talk to NPC'
  description: These fine folks can be found in Goldshire, south of Stormwind.
objectives:
  - talkto 'Brog Hamfist'
  - talkto 'Innkeeper Farley'
  - talkto 2 "Stormwind Guard"]]
  },
  {
    demoId = "tutorial-talkto-horde",
    demoName = "Objective: Talk to NPC",
    helpText = helps.talkto,
    faction = factions.Horde,
    order = 4,
    script = [[
quest:
  name: 'Objective: Talk to NPC'
  description: These upstanding citizens can be found at the zeppelin tower outside of Orgrimmar.
objectives:
  - talkto Frezza
  - talkto "Snurk Bucksquick"
  - talkto 2 "Orgrimmar Grunt"]]
  },
  {
    demoId = "tutorial-emote-ally",
    demoName = "Objective: Use emote",
    helpText = helps.emote,
    faction = factions.Alliance,
    order = 5,
    script = [[
quest:
  name: 'Objective: Use emote'
  description: These eager participants are waiting for you in Goldshire, south of Stormwind.
objectives:
  - emote roar
  - emote cry Tomas
  - emote fart 2 "Stormwind Guard"]]
  },
  {
    demoId = "tutorial-emote-horde",
    demoName = "Objective: Use emote",
    helpText = helps.emote,
    faction = factions.Horde,
    order = 6,
    script = [[
quest:
  name: 'Objective: Use emote'
  description: These willing volunteers can be found in or around the Orgrimmar inn.
objectives:
  - emote dance
  - emote clap Sarok
  - emote smile Kozish
  - emote salute 2 "Orgrimmar Grunt"]]
  },
  {
    demoId = "tutorial-explore-ally",
    demoName = "Objective: Explore",
    helpText = helps.explore,
    faction = factions.Alliance,
    order = 7,
    script = [[
quest:
  name: 'Objective: Explore'
  description: These locations are around Goldshire, south of Stormwind.
objectives:
  - explore "Elwynn Forest"
  - explore "Elwynn Forest" 40.2,74.6
  - explore:
      zone: "Elwynn Forest"
      subzone: "Lion's Pride Inn"
  - explore:
      zone: "Elwynn Forest"
      subzone: "Goldshire"
      coords: 39.5, 64.5]]
  },
  {
    demoId = "tutorial-explore-horde",
    demoName = "Objective: Explore",
    helpText = helps.explore,
    faction = factions.Horde,
    order = 8,
    script = [[
quest:
  name: 'Objective: Explore'
  description: These locations are in northern Durotar, just outside of Orgrimmar.
objectives:
  - explore Durotar
  - explore Durotar 48,12.2
  - explore:
      zone: Durotar
      subzone: "Skull Rock"
  - explore:
      zone: Durotar
      subzone: "Jaggedswine Farm"
      coords: 48.7, 17.2]]
  },
  {
    demoId = "tutorial-startcomplete-ally",
    demoName = "Start/Complete Objectives",
    helpText = helps.Alliance,
    faction = factions.Horde,
    order = 9,
    script = [[
quest:
  name: Start/Complete Objectives (Alliance)
  description: "Will you help me with a task, traveler?"
  completion: "Thank you! Please take this information to the innkeeper."
start:
  text: "%t needs you to gather information from the two guards nearby."
  target: "Marshal Dughan"
objectives:
  - talkto 2 "Stormwind Guard"
complete:
  text: "Deliver the news to %t."
  target: "Innkeeper Farley"]]
  },
}