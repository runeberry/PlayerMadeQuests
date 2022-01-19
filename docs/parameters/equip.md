The **equip** parameter allows you to specify an item that the player must have equipped order to complete an objective.

### Value type

* String - the name of the item as it appears in-game

### Supported objectives

| Objective | How it's used |
|---|---|
| [[cast-spell]] | The item you must have equipped when casting the spell |
| [[equip-item]] | The item you must equip to complete the objective |
| [[explore]] | An item you must have equipped when entering the area to be explored |
| [[gain-aura]] | An item you must have equipped when gaining the aura |
| [[kill]] | An item you must have equipped when killing the target enemy |
| [[loot-item]] | An item you must have equipped when looting the target item |
| [[say]] | An item you must have equipped when saying the message |
| [[talk-to]] | An item you must have equipped when talking to the target NPC |
| [[use-emote]] | An item you must have equipped when using the emote |

### Usage notes

* Currently, there is no localization implemented in the addon, so players using a client in a different language (where the item has a different name) will not be able to progress the objective. The initial release of PMQ is targeting English-language clients only, with localization to come later.
