# equip

<a href="../index.md"><sub>← Home</sub></a>

The **equip** parameter allows you to specify an item that the player must have equipped order to complete an objective.

## Value type

* String - the name of the item as it appears in-game

## Supported objectives

| Objective | How it's used |
|---|---|
| [cast-spell](../objectives/cast-spell.md) | The item you must have equipped when casting the spell |
| [equip-item](../objectives/equip-item.md) | The item you must equip to complete the objective |
| [explore](../objectives/explore.md) | An item you must have equipped when entering the area to be explored |
| [gain-aura](../objectives/gain-aura.md) | An item you must have equipped when gaining the aura |
| [kill](../objectives/kill.md) | An item you must have equipped when killing the target enemy |
| [loot-item](../objectives/loot-item.md) | An item you must have equipped when looting the target item |
| [say](../objectives/say.md) | An item you must have equipped when saying the message |
| [talk-to](../objectives/talk-to.md) | An item you must have equipped when talking to the target NPC |
| [use-emote](../objectives/use-emote.md) | An item you must have equipped when using the emote |

## Usage notes

* Currently, there is no localization implemented in the addon, so players using a client in a different language (where the item has a different name) will not be able to progress the objective. The initial release of PMQ is targeting English-language clients only, with localization to come later.
