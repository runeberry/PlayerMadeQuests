local _, addon = ...

local factions = {
  Alliance = "|cFF33C0FFAlliance|r",
  Horde = "|cFFFF0000Horde|r",
}

local demoinfos = {
  ["basics"] = {
    name = "Lesson 1: The Basics",
    help = "",
  },
  ["kill"] = {
    name = "Lesson 2: Killing Foes",
    help = "",
  },
  ["talk-to"] = {
    name = "Lesson 3: Talking to NPCs",
    help = "",
  },
  ["use-emote"] = {
    name = "Lesson 4: Show your Emotions",
    help = "",
  },
  ["explore"] = {
    name = "Lesson 5: Going Places",
    help = "",
  },
  ["text"] = {
    name = "Lesson 6: Custom Text",
    help = "",
  },
}

local scripts = {
  [1] = [[
quest:
  name: Well Met
  description: So you finished the whole game and you want to make up your own quests now, huh? Well, bein' a quest giver ain't easy. Talk to Marshal Dughan down in Goldshire, he'll get you what you need.
  # you can use > to split your text across multiple lines
  # and %br to add visible line breaks
  completion: >
    Come to learn what it's like to be a questgiver, eh?%br
    Let's see if you've got what it takes.
# 'start' (optional) indicates who you need to target to accept the quest
start:
  target: Jorgen
  zone: Stormwind City
  text: Talk to Jorgen at his fishing spot by the Stormwind City gates.
# 'objectives' are the tasks you must complete for your quest
objectives:
  - explore Goldshire
# 'complete' (optional) indicates who you need to target to turn in the quest
complete:
  target: Marshal Dughan
  zone: Elwynn Forest
  subzone: Goldshire]],
  [2] = [[
quest:
  name: King's Honor, Friend
  description: >
    If you're gonna be giving quests, you ought to know how to kill things.
    And I think I know just where to start.%br
    A local farmer named Rob is having trouble with some wild
    creatures attacking his livestock. Think one of his cows got infected,
    too. Thin out the herd for him, and put that cow to rest while
    you're at it.
  completion: >
    He told you to do what?! I was trying to tame those wild beasts!
    *sigh*... It's okay, they grow back quick enough. Thanks for getting rid
    of that pesky cow, at least.
# 'recommended' or 'required' lets you set requirements for your quest
recommended:
  level: 5
  faction: Alliance
start:
  target: Marshal Dughan
objectives:
  - kill Cow
  - kill 3 'Forest Spider' # multi-word names must be 'quoted'
  - kill 3 "Mangy Wolf" # either single or double quotes are fine
complete:
  target: Rob Bridenbecker]],
  [3] = [[
quest:
  name: Ya Got My Attention
  description: >
    Knowledge is power, right? Well, I sure hope so, because I've been
    paying folks around Goldshire to gather information for me. See what
    they've learned and report back to me.
  completion: >
    They didn't say anything? They just turned and looked at you?%br
    Oh well, maybe they'll prove more capable in a future update...
start:
  target: Marshal Dughan
objectives:
  - talk-to Erma
  - talk-to 'Cylina Darkheart'
  - talk-to 2 "Stormwind Guard" # talk to 2 different targets with this name
complete:
  target: Marshal Dughan]],
  [4] = [[
quest:
  name: Think that's funny, do ya?
  description: >
    Learnin' to be a quest giver? Why would you wanna do that?
    Standin' around with a ! over your head, tellin' the youngins to
    kill the same old boars day-in and day-out... no thanks!%br
    Well, you seem persistent, so let me help. You won't learn anything
    fun from those stodgy old guards. Why don't we help make their
    lives a little more... interesting?
  completion: >
    Ha! Maybe bein' a quest giver could be fun after all...
start:
  target: Kurran Steele
objectives:
  - use-emote flirt 'Marshal Dughan'
  - use-emote fart 2 "Stormwind Guard"
  - use-emote dance # perform this emote with or without a target
complete:
  target: Kurran Steele]],
  [5] = [[
quest:
  name: Safe Travels
  description: >
    There seems to some sort of map carved into the directional sign
    at the intersection in Goldshire. Perhaps it's a treasure map?%br
    You realize that you could probably make a quest out of this.
  completion: >
    You return to the signpost only to find that the carving has vanished.
    Was it all a dream?
# can use a location instead of a target for your start condition
start:
  zone: Elwynn Forest
  subzone: Goldshire
  coords: 42.41,64.47,0.3 # format: "x,y,radius" - radius is optional
objectives:
  - explore 'Crystal Lake'
  # make sure there are no spaces between your coordinate values
  - explore "Crystal Lake" 49.12,65.89
  # objectives can be expanded like this to customize them further
  - explore:
      zone: Elwynn Forest
      subzone: Crystal Lake
      coords: 50.57,66.80
      text: Visit the smaller island in western Crystal Lake.
# can use a location for your complete condition as well
complete:
  zone: Elwynn Forest
  subzone: Goldshire
  coords: 42.41,64.47,0.3
  text: Return to the directional sign in Goldshire.]],
  [6] = [[
quest:
  name: Light Be With You
  description: >
    I've got a quest for ya. Ancient rites and all that. Got it all written
    down right here on this scroll. Don't think too hard about it, just
    play along.%br
    How did I come across it, you ask? Trade secret, sorry.
  completion: >
    Well I'll be, you actually did it. Do you ever wonder why you do
    the things you do? Hmm... we'll ponder that question another day.
start:
  target: William Pestle
  text: Obtain the list of ancient trials from %t. # %t = target
objectives:
  - kill:
      target: Stonetusk Boar
      goal: 3
      text: Sacrifice Stonetusk Boars %p/%g # %p = progress, %g = goal
  - talk-to:
      target: Smith Argus
      text: Deliver news of your conquest to %t
  - use-emote:
      emote: cackle
      target: Chicken
      text: /%em maniacally at the nearest %t # %em = emote
complete:
  target: William Pestle
  text: Inform William that you have completed his trials.]],
  [7] = [[
quest:
  name: Extra Sauce
  description: You're chowing down on some Beer Basted Boar Ribs outside the inn in Razor Hill, but they're a little dry. It appears that the cook didn't sauce them quite enough for your liking. Call to the cook and politely ask for an extra side of sauce. Certainly this is a reasonable request, right?
  # you can use > to split your text across multiple lines
  # and %br to add visible line breaks
  completion: >
    Despite your polite tone, Cook Torka informs you that an extra side
    of sauce will cost 5 copper. Why should you have to pay extra for
    sauce when it's his fault that the ribs were undersauced in the first
    place?%br
    You begin to suspect that Cook Torka intentionally undersauces his ribs
    so that he can charge people extra for sauce.
# 'start' (optional) indicates who you need to target to accept the quest
start:
  target: Cook Torka
  zone: Durotar
  subzone: Razor Hill
# 'objectives' are the tasks you must complete for your quest
objectives:
  - use-emote beckon 'Cook Torka'
# 'complete' (optional) indicates who you need to target to turn in the quest
complete:
  target: Kaplak
  text: Seek out Kaplak in Razor Hill to help you plot your revenge.]],
  [8] = [[
quest:
  name: Rage Against Torka
  description: >
    To exact revenge upon the vile menace Cook Torka, one must first
    build their strength to defeat such a worthy adversary.
    Journey to the south of Razor Hill and let your hatred of Cook Torka
    flow through you as you obliterate these vicious beasts.%br
    If you hesitate to strike down the bunny, try imagining Torka's face on it.
  completion: >
    Ah, I can see that you were successful, as the blood of untamed beasts
    soaks your now-tattered clothes. You didn't actually kill the bunny, right?
    I was kidding about that.
# 'recommended' or 'required' lets you set requirements for your quest
recommended:
  level: 5
  faction: Horde
start:
  target: Kaplak
objectives:
  - kill Hare
  - kill 3 'Dire Mottled Boar' # multi-word names must be 'quoted'
  - kill 3 'Clattering Scorpid' # either single or double quotes are fine
complete:
  target: Kaplak]],
  [9] = [[
quest:
  name: Master of Whispers
  description: >
    Time to dig up some dirt on the rat bastard, sauce miser, and liar
    known as Cook Torka. If you ask the fine citizens of Razor Hill, they
    will surely share tales of his misdeeds, blasphemies, and probable
    felonies.
  completion: >
    Wild parties with gnomes? A drunken brawl with the town guard?
    And he used the eccentric priest, Tai'jin?%br
    I think I know just what needs to be done...
start:
  target: Kaplak
objectives:
  - talk-to Rawrk
  - talk-to 'Innkeeper Grosk'
  - talk-to 2 "Razor Hill Grunt" # talk to 2 different targets with this name
complete:
  target: Kaplak]],
  [10] = [[
quest:
  name: Hearts and Minds
  description: >
    Total vengeance will require the whole town to get involved. Time
    to go out and win some hearts and minds. You need to show this town
    how great you are and what a slack-jawed, sauce-hoarding idiot
    Cook Torka is.
  completion: >
    The town basks in the glow of your charisma and Torka trembles
    in fear of your reckoning. Your hearts and minds campaign to win
    the town over was a massive success. Tai'jin in particular seemed
    impressed with your dance moves...
start:
  target: Kaplak
objectives:
  - use-emote dance # perform this emote with or without a target
  - use-emote stare 'Cook Torka'
  - use-emote salute 2 'Razor Hill Grunt'
complete:
  target: Kaplak]],
  [11] = [[
quest:
  name: Cleansing the Sins
  description: >
    You return to the inn to take a break but are immediately asked to leave.
    Your killing exercise has left you smelling like a murloc's gym bag.%br
    Find a place to bathe, but don't forget to bring a towel. Grab one from the
    barracks before you go.
  completion: >
    The stagnant pond water has cleansed your body, your
    mind, and your soul. You smell wonderful.
# can use a location instead of a target for your start condition
start:
  zone: Durotar
  subzone: Razor Hill
  coords: 51.50,41.62,0.5 # format: "x,y,radius" - radius is optional
  text: Go to the inn at Razor Hill
objectives:
  - explore 'Razor Hill Barracks'
  # make sure there are no spaces between your coordinate values
  - explore Durotar 56.19,46.60,0.3
  # objectives can be expanded like this to customize them further
  - explore:
      zone: Durotar
      coords: 54.42,52.14
      text: Dip your toes in the pond near Tiragarde Keep
# can use a location for your complete condition as well
complete:
  zone: Durotar
  subzone: Razor Hill
  coords: 51.50,41.62,0.5
  text: Return to the inn at Razor Hill, clean and refreshed.]],
  [12] = [[
quest:
  name: Total Torka Takedown
  description: >
    The day has finally come. Time to exact your revenge.
  completion: >
    Cook Torka drops to his knees and begins to grovel.%br
    Fine, I get it! I'll give you the stupid sauce! Just go away and let
    me cook in peace!%br
    He shoves not one, not two, but THREE sides of sauce towards you.
    You stare him dead in the eyes with the intensity of a thousand suns,
    and he understands what you mean. He won't ever undersauce his Beer
    Basted Boar Ribs ever again.%br
    Today was a good day, after all.
start:
  zone: Durotar
  subzone: Razor Hill
  coords: 51.15,42.51,0.2
  text: Start your rampage at Cook Torka's kitchen at %sz. # %sz = subzone
objectives:
  - use-emote:
      emote: cuddle
      target: "Tai'jin"
      text: Cuddle with %t, Cook Torka's ex-girlfriend # %t = target
  - kill:
      target: Dire Mottled Boar
      goal: 3
      text: Kill Cook Torka's stock of %t %p/%g # %p = progress, %g = goal
  - use-emote:
      emote: fart
      target: 'Cook Torka'
      text: /%em in %t's general direction # %em = emote
complete:
  target: Cook Torka
  text: Return to %t and revel in his total annihilation.]],
}

addon.DemoQuestDB = {
  {
    demoId = "demo-basics-ally",
    demoName = demoinfos["basics"].name,
    helpText = demoinfos["basics"].help,
    faction = factions.Alliance,
    order = 1,
    script = scripts[1],
  },
  {
    demoId = "demo-kill-ally",
    demoName = demoinfos["kill"].name,
    helpText = demoinfos["kill"].help,
    faction = factions.Alliance,
    order = 2,
    script = scripts[2],
  },
  {
    demoId = "demo-talk-to-ally",
    demoName = demoinfos["talk-to"].name,
    helpText = demoinfos["talk-to"].help,
    faction = factions.Alliance,
    order = 3,
    script = scripts[3],
  },
  {
    demoId = "demo-use-emote-ally",
    demoName = demoinfos["use-emote"].name,
    helpText = demoinfos["use-emote"].help,
    faction = factions.Alliance,
    order = 4,
    script = scripts[4],
  },
  {
    demoId = "demo-explore-ally",
    demoName = demoinfos["explore"].name,
    helpText = demoinfos["explore"].help,
    faction = factions.Alliance,
    order = 5,
    script = scripts[5],
  },
  {
    demoId = "demo-text-ally",
    demoName = demoinfos["text"].name,
    helpText = demoinfos["text"].help,
    faction = factions.Alliance,
    order = 6,
    script = scripts[6],
  },
  {
    demoId = "demo-basics-horde",
    demoName = demoinfos["basics"].name,
    helpText = demoinfos["basics"].help,
    faction = factions.Horde,
    order = 7,
    script = scripts[7],
  },
  {
    demoId = "demo-kill-horde",
    demoName = demoinfos["kill"].name,
    helpText = demoinfos["kill"].help,
    faction = factions.Horde,
    order = 8,
    script = scripts[8],
  },
  {
    demoId = "demo-talk-to-horde",
    demoName = demoinfos["talk-to"].name,
    helpText = demoinfos["talk-to"].help,
    faction = factions.Horde,
    order = 9,
    script = scripts[9],
  },
  {
    demoId = "demo-use-emote-horde",
    demoName = demoinfos["use-emote"].name,
    helpText = demoinfos["use-emote"].help,
    faction = factions.Horde,
    order = 10,
    script = scripts[10],
  },
  {
    demoId = "demo-explore-horde",
    demoName = demoinfos["explore"].name,
    helpText = demoinfos["explore"].help,
    faction = factions.Horde,
    order = 11,
    script = scripts[11],
  },
  {
    demoId = "demo-text-horde",
    demoName = demoinfos["text"].name,
    helpText = demoinfos["text"].help,
    faction = factions.Horde,
    order = 12,
    script = scripts[12],
  },
}