# cast-spell

[<sub>← Home</sub>](../index.md)

The **cast-spell** objective is triggered whenever the player successfully casts a spell. It will not be triggered when a spell or action fails or is interrupted.

This objective is not limited to just magical spells; it can be invoked by a variety of in-game actions related to abilities, items, or interactions within the world. PMQ includes features to help you find the right names and IDs for spells in the game - see the [spell](../parameters/spell.md) condition page for more information.

## Shorthand

```yaml
objectives:
  # Generic
  - cast-spell goal "spell*" "target"
  # Working examples
  - cast-spell Frostbolt                    # Cast Frostbolt (any rank)
  - cast-spell 3 "Fire Blast"               # Cast Fire Blast 3 times
  - cast-spell 5 Frostbolt "Stonetusk Boar" # Cast Frostbolt on 3 different Stonetusk Boars
```

## Long form

```yaml
objectives:
  - cast-spell:
      spell: Arcane Intellect # Required
      goal: 3
      target: Mangy Wolf
      level: 30
      guild: Pals for Life
      class: Mage
      faction: Alliance
      sametarget: true
      zone: Elwynn Forest
      subzone: Goldshire
      coords: 42.41, 64.47, 0.3
      aura: "Power Word: Fortitude"
      equip: Apprentice's Robe
      item: Light Leather
      text: "Custom display text"
```

_*required_

## Supported parameters

| Parameter | How it's used |
|---|---|
| [aura](../parameters/aura.md) | The name of the aura you must have when casting the spell |
| [class](../parameters/class.md) | The spellcast target must be a player of this class |
| [equip](../parameters/equip.md) | The name of the item you must have equipped when casting the spell |
| [faction](../parameters/faction.md) | The spellcast target must be a player or NPC of this faction (Alliance or Horde) |
| [goal](../parameters/goal.md) | The number of times you must cast the spell |
| [guild](../parameters/guild.md) | The spellcast target must be a player in this guild |
| [item](../parameters/item.md) | The name of the item you must have in your bags when casting the spell |
| [level](../parameters/level.md) | The spellcast target must be this level or higher |
| **sametarget** | If true, then multiple casts on the same target will count toward the objective (default: false) |
| [spell](../parameters/spell.md) | The name or ID of the spell you must cast |
| [target](../parameters/target.md) | The name of the target you must cast the spell on |
| [text](../parameters/text.md) | Custom display text for this objective |
| [zone](../parameters/zone.md)<br/>[subzone](../parameters/zone.md)<br/>[coords](../parameters/coords.md) | The location you must be in when casting the spell |

## Usage notes

* This objective relies on caching player/NPC data while you're playing the game. For more information, see [Save Data & Cache](../guides/save-data.md).
