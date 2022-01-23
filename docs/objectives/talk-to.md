<a href="../index.md"><sub>← Home</sub></a>

# talk-to

The **talk-to** objective is triggered whenever you talk to an NPC, which includes opening their gossip frame, shop window, stable window, or any other window that causes the NPC to face you.

If your goal is to talk to more than 1 of a target NPC, you must talk to different instances of that NPC (e.g. 3 different "Stormwind Guard" NPCs) in order to complete the objective.

In case you cannot talk to the target NPC in game (for example, if you've finished all of their quests and they no longer have any dialogue), then PMQ allows you to use the **/talk** emote on the NPC in order to progress this objective. You must be near the NPC (within approximately 10 yards) in order for this to work.

### Shorthand

```yaml
objectives:
  - talk-to goal "target*"
```

_*required_

### Long form

```yaml
objectives:
  - talk-to:
      target: "Stormwind Guard" # Required
      goal: 3
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
| [aura](../parameters/aura.md) | The name of the aura you must have when talking to the target |
| [equip](../parameters/equip.md) | An item you must have equipped when talking to the target |
| [goal](../parameters/goal.md) | The number of times you must talk to the target |
| [item](../parameters/item.md) | An item you must have in your bags when talking to the target |
| [target](../parameters/target.md) | The name of the NPC to talk to |
| [text](../parameters/text.md) | Custom display text for this objective |
| [zone](../parameters/zone.md)<br/>[subzone](../parameters/zone.md)<br/>[coords](../parameters/coords.md) | The location you must be in when talking to this target |
