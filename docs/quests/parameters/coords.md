[← Back to Objectives](../objectives/index.md)

# x, y, and radius

The **x** and **y** parameters allow you to specify coordinates that need to be visited within a zone. The **radius** parameter lets you define how close you must be to those coordinates in order to progress the objective.

### Value type

* Number - The **x** and **y** values must be coordinate values between 0.00 and 100.00. The **radius** must be a number between 0.00 and 100.00 and represents a distance in coordinate units - **not yards!** The radius defaults to 0.5 coordinate units when not specified.

For example, given the following objective:

```yaml
objectives:
  - explore:
      zone: Elwynn Forest
      x: 38.2
      y: 47.5
      radius: 1
```

The player must enter the box bounded by the top-left coordinate (37.2, 46.5) and the bottom-right coordinate (39.2, 48.5) in order to complete the objective.

### Supported objectives

|Objective|How it's used
|-|-
|**[explore](../objectives/explore.md)**|The coordinates that must be explored

This parameter can also be used as a [start or complete condition](../startcomplete.md).

### Usage notes

* A distance of one "coordinate value" is vastly different between zones, since all map coordinates are normalized to 100 x 100 units. This means that a radius of 0.5 units is much larger in the Barrens compared to Deadwind Pass, since the Barrens is a much larger map.
* The coordinates + radius currently form a square in which the player must explore. This may change to a circle in a future release.