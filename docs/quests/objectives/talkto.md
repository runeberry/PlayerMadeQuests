[← Back to Objectives](index.md)

# talkto

The **talkto** objective is triggered whenever you talk to an NPC, which includes opening their gossip frame, shop window, stable window, or any other window that causes the NPC to face you.

### Alias

This objective can also be written as `talk`.

### Shorthand

```yaml
  - talkto {goal*} {target}
```

*optional

### Supported parameters

|Parameter|How it's used
|-|-
|**[goal](../parameters/goal.md)**|The number of times you must talk to this NPC
|**[target](../parameters/target.md)**|The name of the NPC to talk to
|**[text](../parameters/text.md)**|Custom display text for this objective

### Custom text variables

|Variable|Parameter
|-|-
|**%p**|progress
|**%g**|goal
|**%t**|target