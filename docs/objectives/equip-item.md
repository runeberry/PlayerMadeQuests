# equip-item

The **equip-item** objective is triggered whenever you equip an item.

### Shorthand

```yaml
objectives:
  - equip-item "equip*"
```

_*required_

### Long form

```yaml
objectives:
  - equip-item:
      equip: Loose Chain Mail # Required
      aura: "Power Word: Fortitude"
      item: Light Leather
      zone: Elwynn Forest
      subzone: Goldshire
      coords: 42.41, 64.47, 0.3
      text: "Custom display text"
```

### Supported parameters

| Parameter | How it's used |
|---|---|
| [[aura]] | The name of the aura you must have when equipping the item |
| [[equip]] | The name of the item you must equip |
| [[item]] | The name of another item you must have in your bags when you equip this item |
| [[Display Text | text]] | Custom display text for this objective |
| [[zone]]<br/>[[zone | subzone]]<br/>[[coords]] | The location you must be in when equipping this item |
