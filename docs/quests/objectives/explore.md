[← Back to Objectives](index.md)

# explore

The **explore** objective is used to direct a player to go to a specific area for a quest. This objective is triggered whenever you change zones or subzones.

When you enter a zone or subzone in which you have an objective to explore certain coordinates, PMQ will begin polling on an interval to see if you're within the designated radius of those coordinates. PMQ will stop polling your location when you leave the area or complete the explore objective(s) with coordinates.

### Shorthand

```yaml
  - explore {zone} {coords*}
```

*optional

### Supported parameters

|Parameter|How it's used
|-|-
|**[coords](../parameters/coords.md)**|The precise coordinates to explore in the specified zone
|**[text](../parameters/text.md)**|Custom display text for this objective
|**[zone<br/>subzone](../parameters/zone.md)**|The name of the zone and/or subzone to explore

### Custom text variables

|Variable|Parameter
|-|-
|**%z**|zone
|**%sz**|subzone
|**%co**|coords
|**%x**|x-coordinate of coords
|**%y**|y-coordinate of coords
|**%r**|radius of coords
|**%xy**|coords formatted as: `(x, y)`
|**%xyr**|coords formatted as: `(x, y) +/- radius`