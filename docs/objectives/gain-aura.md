# gain-aura

The **gain-aura** objective is triggered whenever you gain a buff or debuff.

### Shorthand

```yaml
objectives:
  - gain-aura "aura*"
```

_*required_

### Long form

```yaml
objectives:
  - gain-aura:
      aura: "Power Word: Fortitude" # Required
      equip: Loose Chain Mail
      item: Light Leather
      zone: Elwynn Forest
      subzone: Goldshire
      coords: 42.41, 64.47, 0.3
      text: "Custom display text"
```

### Supported parameters

| Parameter | How it's used |
|---|---|
| [[aura]] | The name of the aura you must gain to complete this objective |
| [[equip]] | An item you must have equipped when gaining this aura |
| [[item]] | An item you must have in your bags when gaining this aura |
| [[Display Text | text]] | Custom display text for this objective |
| [[zone]]<br/>[[zone | subzone]]<br/>[[coords]] | The location you must be in when gaining the aura |
