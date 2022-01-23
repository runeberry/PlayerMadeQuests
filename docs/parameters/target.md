# target

[<sub>← Home</sub>](../index.md)

The **target** parameter is used in a variety of ways, but in general it is used to specify the monster, NPC, or player that must be targeted in order to progress an objective.

## Value type

* String - the name of the monster or NPC as it appears in-game

## Supported objectives

| Objective | How it's used |
|---|---|
| [cast-spell](../objectives/cast-spell.md) | The target that you must cast a spell on |
| [kill](../objectives/kill.md) | The target that must be killed |
| [talk-to](../objectives/talk-to.md) | The target that must be talked to |
| [use-emote](../objectives/use-emote.md) | The target which the emote must be used on |

This parameter can also be used as a [start or complete condition](../guides/start-complete.md).

## Unique Targets

For objectives requiring you to act on the same target multiple times (i.e. with a goal &gt; 1), you must target "unique instances" of a monster or NPC in order to progress the objective. However, this unique-target restriction **does not apply to players**. Consider the following example:

* `use-emote salute 5 "Stormwind Guard"` - You must salute 5 _different_ Stormwind Guards to complete this objective.
* `use-emote salute 5 Questborther` - Assuming Questborther is a player's name, you can salute that same player 5 times to complete this objective.

## Usage notes

* The target's name must be spelled and capitalized exactly as it is in-game in order for the objective to progress.
* Currently, there is no localization implemented in the addon, so players using a client in a different language (where the target has a different name) will not be able to progress the objective. The initial release of PMQ is targeting English-language clients only, with localization to come later.
