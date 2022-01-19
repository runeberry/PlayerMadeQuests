# item

{{About|This page refers to items as they are used with [[Objective|quest objectives]]. For items used as quest rewards, see [[Item (Rewards)]].}}

The **item** parameter allows you to specify an item that the player must have in their bags in order to complete an objective.

### Value type

* String - the name of the item as it appears in-game

### Supported objectives

| Objective | How it's used |
|---|---|
| [[cast-spell]] | An item you must have in your bags when casting the spell |
| [[equip-item]] | An item you must have in your bags when equipping the item specified with the [[equip]] parameter |
| [[explore]] | An item you must have in your bags when entering the area to be explored |
| [[gain-aura]] | An item you must have in your bags when gaining the aura |
| [[kill]] | An item you must have in your bags when killing the target enemy |
| [[loot-item]] | The item you must loot |
| [[say]] | An item you must have in your bags when saying the message |
| [[talk-to]] | An item you must have in your bags when talking to the target NPC |
| [[use-emote]] | An item you must have in your bags when using the emote |

### Usage notes

* It is currently not possible to specify a quantity of an item that the player must have in their bags. However, this is planned for a release in the near future.
* Currently, there is no localization implemented in the addon, so players using a client in a different language (where the item has a different name) will not be able to progress the objective. The initial release of PMQ is targeting English-language clients only, with localization to come later.
