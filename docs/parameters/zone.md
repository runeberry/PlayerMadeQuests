The **zone** and **subzone** parameters are used to specify the names of in-game areas where an objective must be completed.

### Value type

* String - the name of a zone or subzone as it appears in-game

### Supported objectives

| Objective | How it's used |
|---|---|
| [[cast-spell]] | The zone where you must be when casting the spell |
| [[equip-item]] | The zone where you must be when equipping the item |
| [[explore]] | The zone where you must be in order to complete the objective |
| [[gain-aura]] | The zone where you must gain the aura |
| [[kill]] | The zone where you must kill the target |
| [[loot-item]] | The zone where you must loot the item |
| [[say]] | The zone you must be in when saying the message |
| [[talk-to]] | The zone where you must talk to the target |
| [[use-emote]] | The zone where you must use the emote |

This parameter can also be used as a [[Start &amp; Complete Objectives|start or complete condition]].

### Usage notes

* Zone and subzone are completely interchangeable - both parameters will look at both your current zone and subzone for a match when evaluating objectives.
* The zone's name must be spelled and capitalized exactly as it is in-game in order for the objective to progress.
* Currently, there is no localization implemented in the addon, so players using a client in a different language (where the zone has a different name) will not be able to progress the objective. The initial release of PMQ is targeting English-language clients only, with localization to come later.
