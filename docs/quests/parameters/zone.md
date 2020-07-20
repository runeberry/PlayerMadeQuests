[← Back to Objectives](../objectives/index.md)

# zone & subzone

The **zone** and **subzone** parameters are used to specify the names of in-game areas where an objective must be completed.

### Value type

* String - the name of a zone or subzone as it appears in-game

### Supported objectives

|Objective|How it's used
|-|-
|**[explore](../objectives/explore.md)**|The name of the zone or subzone that must be explored

This parameter can also be used as a [start or complete condition](../startcomplete.md).

### Usage notes

* Zone and subzone are completely interchangeable - both parameters will look at both your current zone and subzone for a match when evaluating objectives.
* The zone's name must be spelled and capitalized exactly as it is in-game in order for the objective to progress.
* Currently, there is no localization implemented in the addon, so players using a client in a different language (where the zone has a different name) will not be able to progress the objective. The initial release of PMQ is targeting English-language clients only, with localization to come later.