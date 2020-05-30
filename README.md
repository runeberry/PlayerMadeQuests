# PlayerMadeQuests

Create and share your own custom quests in World of Warcraft: Classic!

## Planned Features

This isn't really a roadmap, just brainstorming some features I would like to see in the addon, in no particular order.

### Quest ideas

* Objectives
  * ✔️ Kill Mob (v0.0.1-alpha)
  * ✔️ Talk to NPC (v0.0.1-alpha)
  * Buy from / sell to merchant
  * Visit location
  * ✔️ Use emote on NPC (v0.0.1-alpha)
  * Acquire a buff/debuff
  * Obtain an item
  * Equip an item
  * Have several items equipped
  * Cast a spell
  * Deal an amount of damage (of a certain type)
* Conditions: Complete an objective while...
  * ✔️ targeting a specific NPC (v0.0.1-alpha)
  * having a certain buff/debuff
  * having a certain amount of money
  * having a certain item(s) in your bag
  * having a certain item(s) equipped
  * being a certain stance or form
  * being in a certain zone
  * being within a certain radius of coordinates
* Requirements or Recommendations
  * Level range
  * Must be a certain class
  * Must be a certain faction
  * Must have a certain reputation level
  * Must have a certain profession (level)
* Other features
  * ✔️ Quest descriptions (v0.0.1-alpha)
  * Quest Completion prompt, which would remove (archive) it from the log
    * With a separate description
  * Quest chains
    * Must have a certain prerequisite quest completed
    * May choose a branch in a quest, possibly locking out other branches
  * Quest start/complete locations
    * Must talk to certain NPCs or visit certain locations to start/complete quests
    * But is this actually fun? I think starting/completing from anywhere is just better.

### For Alpha-ready

* Cleanup QuestLogFrame.lua - it works, but it's a mess
  * ✔️ Extract common methods into a common Lua file, like FramesCore.lua (v0.0.1-alpha, as CustomWidgets.lua)
  * Figure out a good way to save window size/position
* Add some basic objectives
  * ✔️ Talk to NPC (v0.0.1-alpha)
  * Go to location
  * Use emote
* ✔️ Simplify adding custom quests in Lua - since Quest Builder UI is pretty far off (v0.0.1-alpha, as DemoQuests and the QuestScript editor)

### For Beta-ready

* ✔️ Add objective conditions - complete objective while... (v0.0.1-alpha)
  * A certain item is equipped
  * In a certain location
* Binary objective conditions - (A or B) and (X or Y)
* ✔️ Share quest over addon message channels (v0.0.1-alpha)
* ✔️ Add quest descriptions (v0.0.1-alpha)
* Debug UI
* Write logs to SavedVariables

### For Release

* Quest discoverability through addon channels
* Quest builder UI
* Settings UI

### Nice to have

* Completion objectives (must "turn-in" to an NPC or Player)
* Account-wide / Global quests?