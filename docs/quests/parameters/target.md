[← Back to Objectives](../objectives/index.md)

# target

The **target** parameter is used in a variety of ways, but in general it is used to specify the monster or NPC that must be targeted in order to progress an objective.

### Value type

* String - the name of the monster or NPC as it appears in-game

### Supported objectives

|Objective|How it's used
|-|-
|**[emote](../objectives/emote.md)**|The target which the emote must be used on
|**[kill](../objectives/kill.md)**|The target that must be killed
|**[talkto](../objectives/talkto.md)**|The target that must be talked to

This parameter can also be used as a [start or complete condition](../startcomplete.md).

### Usage notes

* The target's name must be spelled and capitalized exactly as it is in-game in order for the objective to progress.
* Currently, there is no localization implemented in the addon, so players using a client in a different language (where the target has a different name) will not be able to progress the objective. The initial release of PMQ is targeting English-language clients only, with localization to come later.