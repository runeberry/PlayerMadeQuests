The **explore** objective is used to direct a player to go to a specific area for a quest. This objective is triggered whenever you change zones or subzones.

When you enter a zone or subzone in which you have an objective to explore certain coordinates, PMQ will begin polling on an interval to see if you're within the designated radius of those coordinates. PMQ will stop polling for your location when you leave the area of that objective or complete that objective.

### Shorthand

```yaml
objectives:
  - explore "zone*" "coords"
```

_*required_

### Long form

```yaml
objectives:
  - explore:
      zone: Elwynn Forest # Required
      subzone: Goldshire
      coords: 42.41, 64.47, 0.3
      aura: "Power Word: Fortitude"
      equip: Loose Chain Mail
      item: Light Leather
      text: "Custom display text"
```

### Supported parameters

| Parameter | How it's used |
|---|---|
| [[aura]] | The aura you must have when exploring this area |
| [[equip]] | An item you must have equipped when exploring this area |
| [[item]] | An item you must have in your bags when exploring this area |
| [[Display Text | text]] | Custom display text for this objective |
| [[zone]]<br/>[[zone | subzone]]<br/>[[coords]] | The location that must be visited to complete this objective |
