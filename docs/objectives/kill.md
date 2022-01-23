# kill

[<sub>← Home</sub>](../index.md)

The **kill** objective is triggered whenever you or someone in your party kills a monster or NPC in combat. Your party must have the tag on an enemy when it dies in order to gain progress.

## Shorthand

```yaml
objectives:
  - kill goal "target*"
```

_*required_

## Long form

```yaml
objectives:
  - kill:
      goal: 3
      target: Mangy Wolf
      level: 30
      guild: Pals for Life
      class: Mage
      faction: Alliance
      zone: Elwynn Forest
      subzone: Goldshire
      coords: 42.41, 64.47, 0.3
      aura: "Power Word: Fortitude"
      equip: Loose Chain Mail
      item: Light Leather
      text: "Custom display text"
```

## Supported parameters

| Parameter | How it's used |
|---|---|
| [aura](../parameters/aura.md) | The name of the aura you must have when killing the target |
| [class](../parameters/class.md) | The kill target must be a player of this class |
| [equip](../parameters/equip.md) | An item you must have equipped when killing the target |
| [faction](../parameters/faction.md) | The kill target must be a player or NPC of this faction (Alliance or Horde) |
| [goal](../parameters/goal.md) | The number of enemies to kill |
| [guild](../parameters/guild.md) | The kill target must be a player in this guild |
| [item](../parameters/item.md) | An item you must have in your bags when killing the target |
| [level](../parameters/level.md) | The kill target must be this level or higher |
| [target](../parameters/target.md) | The name of the NPC or player to kill |
| [text](../parameters/text.md) | Custom display text for this objective |
| [zone](../parameters/zone.md)<br/>[subzone](../parameters/zone.md)<br/>[coords](../parameters/coords.md) | The location you must be in when killing the target |

## Notes

* This objective contains additional logic to count players' pet contributions as kills. In short, when your pet attacks any target, you will get kill credit for that target when it dies. This behavior can be toggled off with the FEATURE_PET_KILLS setting in the [Configuration](../guides/Configuration.md) menu. If this behavior is inaccurate or causing problems, let us known on Discord!
* This objective relies on caching player/NPC data while you're playing the game. For more information, see [Save Data & Cache](../guides/save-data.md).
