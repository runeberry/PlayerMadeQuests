# text

<a href="../index.md"><sub>← Home</sub></a>

The **text** parameter allows you to precisely define how your quest information will be displayed when it's presented to players. PMQ will automatically generate text for your quest objectives, requirements, and more based on the information that you provide, but overriding this with the **text** parameter will allow you to give your quests a little more personality beyond the standard text.

## Value type

* String or table - you can specify a single text string that will be used for all use cases, or you can specify different strings for each use case. See the examples below.

## Supported objectives

| Objective | How it's used |
|---|---|
| [cast-spell](../objectives/cast-spell.md) | Custom display text |
| [equip-item](../objectives/equip-item.md) | Custom display text |
| [gain-aura](../objectives/gain-aura.md) | Custom display text |
| [explore](../objectives/explore.md) | Custom display text |
| [kill](../objectives/kill.md) | Custom display text |
| [loot-item](../objectives/loot-item.md) | Custom display text |
| [say](../objectives/say.md) | Custom display text |
| [talk-to](../objectives/talk-to.md) | Custom display text |
| [use-emote](../objectives/use-emote.md) | Custom display text |

Custom display text can also be used with a [start and complete conditions](../guides/start-complete.md) as well as [quest requirements](../guides/requirements.md).

## Usage notes

```yaml
start:
  zone: Azshara
  text: Go to the treacherous cliffs north of Orgrimmar to begin this quest.
```

With the above configuration, your custom text will be displayed wherever PMQ displays information about the `start` objective for a quest.

You can take this a step further and specify different text for different contexts within PMQ. See the following example:

```yaml
objectives:
  - explore:
      zone: Azshara
      x: 38.9
      y: 47.2
      text:
        log: Go to the secret spot
        progress: Secret spot uncovered
        quest: Find the hero's secret spot in %z
```

With this configuration, you will see different custom text displayed in the quest log, progress message, and quest info frame, instead of the same line of text for all 3 cases. Any cases not specified under `text` will fall back on the default display text provided by PMQ.

You may also notice the use of `%z` in the text above. This will get populated with the value of `zone` when the text is displayed. Each objective supports a set of these variables for custom text to reduce the amount of repetition in your script - these variables are listed below.

## Display text variables

You can use special variables in your display text string to show the value of different parameters for that objective.

| Variable | Description |
|---|---|
| **%a** | [aura](../parameters/aura.md) |
| **%co** | [coords](../parameters/coords.md) |
| **%ch** | [channel](../parameters/channel.md) |
| **%e** | [equip](../parameters/equip.md) |
| **%em** | [emote](../parameters/emote.md) |
| **%g** | [goal](../parameters/goal.md) |
| **%i** | [item](../parameters/item.md) |
| **%lang** | [language](../parameters/language.md) |
| **%msg** | [message](../parameters/message.md) |
| **%p** | [progress](../parameters/goal.md) |
| **%t** | [target](../parameters/target.md) or [recipient](../parameters/recipient.md) |
| **%sz** | [subzone](../parameters/zone.md) |
| **%z** | [zone](../parameters/zone.md) |
| **%g2** | prints **goal** only if goal > 1 |
| **%p2** | prints **progress** only if progress < goal |
| **%r** | radius of **coords** |
| **%x** | x-coordinate of **coords** |
| **%xy** | **coords** formatted as: `(x, y)` |
| **%xyr** | **coords** formatted as: `(x, y) +/- radius` |
| **%xyz** | location formatted as: `(x, y) in zone in subzone` |
| **%y** | y-coordinate of **coords** |
| **%z2** | location formatted as: `zone in subzone` |

## Quest-level variables

The following variables can be used in the quest's `description` or `completion` fields to provide some dynamic flair to your quest text. The Player Info variables will change based on the player who's currently playing the quest.

The `%gen` variable is intended to be used as a flag that can result in different text depending on the player's gender. See how it's used in this example:

```yaml
quest:
  name: Joining the Team
  description: So you're the infamous %name, huh? Aren't you kinda short for a %race?
  completion: Well I'll be, you actually did it! Not bad for a %class. Glad to have a [%gen:guy|gal] like you on our team.
```

| Variable | Description
|---|---|
| **%name** | The player's name |
| **%class** | The player's class (e.g. "Mage") |
| **%race** | The player's race (e.g. "Tauren") |
| **%gen** | The player's gender flag (see example above) |
| **%author** | The name of the player who wrote the quest |
| **%giver** | The name of the player who shared the quest (changes every time the quest is shared) |
| **%n** | newline for [long strings](../guides/yaml-crash-course.md) |
| **%br** | line-break (double newline) for [long strings](../guides/yaml-crash-course.md) |
