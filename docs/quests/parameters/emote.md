[← Back to Objectives](../objectives/index.md)

# emote

The **emote** parameter is only available for use with the [emote objective](../objectives/emote.md). It allows you to specify which emote should trigger the objective.

### Value type

* String - the name of the emote to use, without the slash

### Supported objectives

|Objective|How it's used
|-|-
|**[emote](../objectives/emote.md)**|The name of the emote to use

### Usage notes

* Any emotes that cause the same chat message will all be able to trigger the objective. For example, if the emote parameter is "laugh", then both `/laugh` and `/lol` will satisfy the objective.