# goal

The **goal** parameter is available to most objectives to specify how many times that objective must be triggered in order to be marked "complete". For example, in the objective "kill 5 Chicken", `5` is considered the goal.

Some objectives do not support a goal parameter because it doesn't make sense to complete them more than once in the same quest. For example, the **explore** objective does not support a goal - why would you need to explore the same area twice?

### Value type

* Number - must be a whole number greater than 0

### Supported objectives

| Objective | How it's used |
|---|---|
| [cast-spell](../objectives/cast-spell.md) | The number of times you must cast the spell |
| [kill](../objectives/kill.md) | The number of times the target must be killed |
| [loot-item](../objectives/loot-item.md) | The number of items you must loot |
| [talk-to](../objectives/talk-to.md) | The number of times the target must be talked to |
| [use-emote](../objectives/use-emote.md) | The number of times the emote must be used |

### Usage notes

* When a goal is not specified on an objective, it always defaults to 1.
