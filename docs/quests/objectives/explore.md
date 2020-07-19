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
|**[radius](../parameters/coords.md)**|The number of enemies to kill
|**[subzone](../parameters/zone.md)**|The name of the subzone to explore
|**[text](../parameters/text.md)**|Custom display text for this objective
|**[x](../parameters/coords.md)**|The x-coordinate of the location
|**[y](../parameters/coords.md)**|The y-coordinate of the location
|**[zone](../parameters/zone.md)**|The name of the zone to explore

### Custom text variables

|Variable|Parameter
|-|-
|**%r**|radius
|**%sz**|subzone
|**%x**|x
|**%y**|y
|**%z**|zone