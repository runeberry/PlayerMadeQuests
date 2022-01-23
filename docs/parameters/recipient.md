<a href="../index.md"><sub>← Home</sub></a>

# recipient

The **recipient** parameter allows you to specify the name of a player which must receive an objective in order for it to be completed.

### Value type

* String - the player character's name. This should be the character's name only, do not include their realm.

### Supported objectives

| Objective | How it's used |
|---|---|
| [say](../objectives/say.md) | The player character(s) which you must whisper in order to complete the objective |

### Usage notes

* Player names are case-sensitive, so make sure you capitalize the first letter of the player's name!
* You do not need to specify `channel: whisper` on a [Say](../objectives/say.md) objective if you specify a recipient. Since whispers are the only channel that are targeted toward a specific player, the whisper channel is implied by specifying a recipient.
* You can specify multiple recipients, which means that interacting with *any one* of these recipients will satisfy the objective. For example:

```yaml
objectives:
  - say:
      message: "wash yer back"
      recipient: [ Playerone, Playertwo ] # You can message either Playerone or Playertwo to complete this objective
```
