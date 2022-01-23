# emote

[<sub>← Home</sub>](../index.md)

The **emote** parameter is only available for use with the [use-emote](../objectives/use-emote.md) objective. It allows you to specify which emote should trigger the objective.

## Value type

* String - the name of the emote to use, without the slash

## Supported objectives

| Objective | How it's used |
|---|---|
| [use-emote](../objectives/use-emote.md) | The name of the emote to use |

## Usage notes

* Any emotes that cause the same chat message will all be able to trigger the objective. For example, if the emote parameter is "laugh", then both `/laugh` and `/lol` will satisfy the objective.
