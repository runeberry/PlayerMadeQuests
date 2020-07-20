[← Back to Objectives](index.md)

# emote

The **emote** objective is triggered whenever you use an emote, such as `/dance` or `/glare`. This objective cannot be triggered by custom emotes sent with the `/e` command.

### Shorthand

```yaml
  - emote {emote} {goal*} {target*}
```

*optional

### Supported parameters

|Parameter|How it's used
|-|-
|**[emote](../parameters/emote.md)**|The name of the emote to use, without the slash
|**[goal](../parameters/goal.md)**|The number of times you must use this emote
|**[target](../parameters/target.md)**|The name of the NPC that must be targeted when the emote is used
|**[text](../parameters/text.md)**|Custom display text for this objective.

### Custom text variables

|Variable|Parameter
|-|-
|**%em**|emote
|**%g**|goal
|**%p**|progress
|**%t**|target