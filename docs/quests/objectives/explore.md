[← Back to Objectives](index.md)

# explore

The **explore** objective is used to direct a player to go to a specific area for a quest. This objective is triggered whenever you change zones or subzones.

When you enter a zone or subzone in which you have an objective to explore certain coordinates, PMQ will begin polling on an interval to see if you're within the designated radius of those coordinates. PMQ will stop polling your location when you leave the area or complete the explore objective(s) with coordinates.

### Shorthand

```yaml
  - explore {zone} {x*} {y*} {radius*}
```

*optional

### Supported parameters

|Parameter|How it's used
|-|-
|**[text](../parameters/text.md)**|Custom display text for this objective
|**[x<br/>y<br/>radius](../parameters/coords.md)**|The coordinates to explore, and how close you must get to explore them
|**[zone<br/>subzone](../parameters/zone.md)**|The name of the zone and/or subzone to explore

### Custom text variables

|Variable|Parameter
|-|-
|**%r**|radius
|**%sz**|subzone
|**%x**|x
|**%y**|y
|**%z**|zone