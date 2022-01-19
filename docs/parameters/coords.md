# coords

The **coords** parameter allow you to specify the `x,y` coordinates that need to be visited within a zone, as well as the `radius` you must be from those coordinates in order to progress an objective.

### Value type

* String - The **coords** value is expressed as a comma-separated string that is parsed into `x`, `y`, and `radius` values at runtime. The values must be in the following ranges:
* `x` and `y` must be between 0.00 and 100.00, representing coordinate values on the map
* `radius` must be between 0.00 and 100.00, representing a distance in coordinate units - **not yards!** PMQ will use a default radius of 0.5 units if no radius is specified.

See the following examples showing how **coords** can be written.

```yaml
objectives:
  - explore:
      zone: Elwynn Forest
      coords: 38,72               # Coordinates can be whole numbers
  - explore:
      zone: Elwynn Forest
      coords: 38.51,72.64         # Or you can get precise with decimals
  - explore:
      zone: Elwynn Forest
      coords: 38.51,72.64,0.8     # You can add a custom radius, too
  - explore:
      zone: Elwynn Forest
      coords: 38.51, 72.64, 0.8   # A little space is fine, as a treat
```

Note that when using **coords** in a shorthand objective, the string must not contain any spaces. However, if you want to include spaces, you can do so safely by wrapping the value in quotes.

```yaml
objectives:
  - explore Durotar 22.1,47.6          # OK
  - explore Durotar 22.1,47.6,0.25     # OK
  - explore Durotar 22.1, 47.6, 0.25   # Not OK! Coords will get broken apart
  - explore Durotar '22.1, 47.6, 0.25' # OK (either double or single quotes)
  - explore 'Elwynn Forest'            # Same rule applies to 'zone'
```

Here's a practical example explained. Given the following objective:

```yaml
objectives:
  - explore:
      zone: Elwynn Forest
      coords: 38.2, 47.5, 1
```

The player must enter the box bounded by the top-left coordinate (37.2, 46.5) and the bottom-right coordinate (39.2, 48.5) in [https://wow.gamepedia.com/Elwynn_Forest Elwynn Forest] order to complete the objective.

### Supported objectives

| Objective | How it's used |
|---|---|
| [[equip-item]] | The coordinates you must be near when equipping the item |
| [[explore]] | The coordinates you must be near in order to complete the objective |
| [[gain-aura]] | The coordinates where you must gain the aura |
| [[kill]] | The coordinates where you must kill the target |
| [[loot-item]] | The coordinates where you must loot the item |
| [[say]] | The coordinates where you must say the message |
| [[talk-to]] | The coordinates where you must talk to the target |
| [[use-emote]] | The coordinates where you must use the emote |

This parameter can also be used as a [[Start &amp; Complete Objectives|start or complete condition]].

### Usage notes

* A distance of one "coordinate value" is vastly different between zones, since all map coordinates are normalized to 100 x 100 units. This means that a radius of 0.5 units is much larger in the Barrens compared to Deadwind Pass, since the Barrens is a much larger map.
* The coordinates + radius currently form a square in which the player must explore. This may change to a circle in a future release.
* Unfortunately, the WoW client does not expose a way to read a player's `z` (height) coordinate, so it is not possible to include this in the **coords** parameter.
