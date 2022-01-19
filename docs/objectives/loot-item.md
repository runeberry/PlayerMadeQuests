# loot-item

The **loot-item** objective is triggered whenever you loot an item from any source. Specifically, this is triggered by any event that can write a loot message to the chatbox. This includes:

* Looting items from bodies
* Harvesting items with gathering skills
* Looting items from containers (like lockboxes, world chests)

### Shorthand

```yaml
objectives:
  - loot-item goal "item*"
```

_*required_

### Long form

```yaml
objectives:
  - loot-item:
      item: Light Leather # Required
      goal: 5
      equip: Loose Chain Mail
      aura: "Power Word: Fortitude"
      zone: Elwynn Forest
      subzone: Goldshire
      coords: 42.41, 64.47, 0.3
      text: "Custom display text"
```

### Supported parameters

| Parameter | How it's used |
|---|---|
| [[aura]] | The name of the aura you must have when looting |
| [[equip]] | The name of an item you must have equipped when looting |
| [[goal]] | The number of items you must loot |
| [[item]] | The name of the item you must loot |
| [[Display Text | text]] | Custom display text for this objective |
| [[zone]]<br/>[[zone | subzone]]<br/>[[coords]] | The location you must be in when looting this item |
