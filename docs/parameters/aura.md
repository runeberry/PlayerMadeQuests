# aura

<a href="../index.md"><sub>← Home</sub></a>

The **aura** parameter allows you to specify any aura (buff or debuff) that the player must have in order to trigger an objective.

### Value type

* String - the name of the aura as it appears in-game

### Supported objectives

| Objective | How it's used |
|---|---|
| [cast-spell](../objectives/cast-spell.md) | The aura you must have when casting the spell |
| [equip-item](../objectives/equip-item.md) | The aura you must have when equipping the item |
| [explore](../objectives/explore.md) | The aura you must have when entering the area to be explored |
| [gain-aura](../objectives/gain-aura.md) | The aura you must gain |
| [kill](../objectives/kill.md) | The aura you must have when killing the target enemy |
| [loot-item](../objectives/loot-item.md) | The aura you must have when looting an item |
| [say](../objectives/say.md) | The aura you must have when saying the message |
| [talk-to](../objectives/talk-to.md) | The aura you must have when talking to the target NPC |
| [use-emote](../objectives/use-emote.md) | The aura you must have when performing the emote |

### Usage notes

* The aura's name must be spelled and capitalized exactly as it is in-game in order for the objective to progress.
* Currently, there is no localization implemented in the addon, so players using a client in a different language (where the aura has a different name) will not be able to progress the objective. The initial release of PMQ is targeting English-language clients only, with localization to come later.
