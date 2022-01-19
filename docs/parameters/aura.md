# aura

The **aura** parameter allows you to specify any aura (buff or debuff) that the player must have in order to trigger an objective.

### Value type

* String - the name of the aura as it appears in-game

### Supported objectives

| Objective | How it's used |
|---|---|
| [[cast-spell]] | The aura you must have when casting the spell |
| [[equip-item]] | The aura you must have when equipping the item |
| [[explore]] | The aura you must have when entering the area to be explored |
| [[gain-aura]] | The aura you must gain |
| [[kill]] | The aura you must have when killing the target enemy |
| [[loot-item]] | The aura you must have when looting an item |
| [[say]] | The aura you must have when saying the message |
| [[talk-to]] | The aura you must have when talking to the target NPC |
| [[use-emote]] | The aura you must have when performing the emote |

### Usage notes

* The aura's name must be spelled and capitalized exactly as it is in-game in order for the objective to progress.
* Currently, there is no localization implemented in the addon, so players using a client in a different language (where the aura has a different name) will not be able to progress the objective. The initial release of PMQ is targeting English-language clients only, with localization to come later.
