# gain-aura

[<sub>← Home</sub>](../index.md)

The **gain-aura** objective is triggered whenever you gain a buff or debuff.

## Shorthand

```yaml
objectives:
  - gain-aura "aura*"
```

_*required_

## Long form

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

## Supported parameters

| Parameter | How it's used |
|---|---|
| [aura](../parameters/aura.md) | The name of the aura you must gain to complete this objective |
| [equip](../parameters/equip.md) | An item you must have equipped when gaining this aura |
| [item](../parameters/item.md) | An item you must have in your bags when gaining this aura |
| [text](../parameters/text.md) | Custom display text for this objective |
| [zone](../parameters/zone.md)<br/>[subzone](../parameters/zone.md)<br/>[coords](../parameters/coords.md) | The location you must be in when gaining the aura |
