# PlayerMadeQuests

Create and share your own custom quests in World of Warcraft: Classic!

## TODO

### For Alpha-ready

* Cleanup QuestLogFrame.lua - it works, but it's a mess
  * Extract common methods into a common Lua file, like FramesCore.lua
  * Figure out a good way to save window size/position
  * Might be easier once there's a 2nd window in play
* Add some basic objectives
  * ✔️ Talk to NPC
  * Go to location
  * Use emote (on unit, which might be a condition)
* ✔️ Simplify adding custom quests in Lua - since Quest Builder UI is pretty far off

### For Beta-ready

* Add objective conditions - complete objective while...
  * A certain item is equipped
  * In a certain location
* Binary objective conditions - (A or B) and (X or Y)
* Share quest over addon message channels
* Add quest descriptions
* Debug UI
* Write logs to SavedVariables

### For Release

* Quest discoverability through addon channels
* Quest builder UI
* Settings UI

### Nice to have

* Completion objectives (must "turn-in" to an NPC or Player)
* Account-wide / Global quests?