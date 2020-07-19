[← Back to Objectives](../objectives/index.md)

# goal

The **goal** parameter is available to most objectives to specify how many times that objective must be triggered in order to be marked "complete". For example, in the objective "kill 5 Chicken", `5` is considered the goal.

Some objectives do not support a goal parameter because it doesn't make sense to complete them more than once in the same quest. For example, the **explore** objective does not support a goal - why would you need to explore the same area twice?

### Value type

* Number - must be a whole number greater than 0

### Supported objectives

|Objective|How it's used
|-|-
|**[emote](../objectives/emote.md)**|The number of times the emote must be used
|**[kill](../objectives/kill.md)**|The number of times the target must be killed
|**[talkto](../objectives/talkto.md)**|The number of times the target must be talked to

### Usage notes

* When a goal is not specified on an objective, it always defaults to 1.