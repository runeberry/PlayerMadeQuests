The **use-emote** objective is triggered whenever you use an emote, such as `/dance` or `/glare`. This objective cannot be triggered by custom emotes sent with the `/e` command.

If your goal is to use an emote more than 1 time on a target NPC, you must use the emote on different instances of that NPC (e.g. 3 different "Stormwind Guard" NPCs) in order to complete the objective.

### Shorthand

```yaml
objectives:
  - use-emote "emote*" goal "target"
```

_*required_

### Long form

```yaml
objectives:
  - use-emote:
      goal: 3
      emote: dance # Required
      target: "Stormwind Guard"
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

### Supported parameters

| Parameter | How it's used |
|---|---|
| [[aura]] | The name of the aura you must have when using the emote |
| [[class]] | The emote target must be a player of this class |
| [[emote]] | The name of the emote you must use |
| [[equip]] | An item you must have equipped when using the emote |
| [[faction]] | The emote target must be a player or NPC of this faction (Alliance or Horde) |
| [[goal]] | The number of times you must use the emote |
| [[guild]] | The emote target must be a player in this guild |
| [[item]] | An item you must have in your bags when using the emote |
| [[level]] | The emote target must be this level or higher |
| [[target]] | The name of the monster or NPC to use the emote on |
| [[Display Text | text]] | Custom display text for this objective |
| [[zone]]<br/>[[zone | subzone]]<br/>[[coords]] | The location you must be in when using the emote |
