[← Back to Objectives](index.md)

# kill

The **kill** objective is triggered whenever you or someone in your party kills a monster or NPC in combat. Your party must have the tag on an enemy when it dies in order to gain progress.

### Shorthand

```yaml
  - kill {goal*} {target}
```

*optional

### Parameters

|Parameter|How it's used
|-|-
|**[goal](../parameters/goal.md)**|The number of enemies to kill
|**[target](../parameters/target.md)**|The name of the monster or NPC to kill
|**[text](../text.md)**|Custom display text for this objective

### Custom text variables

|Variable|Parameter
|-|-
|**%p**|progress
|**%g**|goal
|**%t**|target