[← Back to Objectives](../objectives/index.md)

# text

The **text** parameter allows you to precisely define how your quest information will be displayed when it's presented to players. PMQ will automatically generate text for your quest objectives, requirements, and more based on the information that you provide, but overriding this with the **text** parameter will allow you to give your quests a little more personality beyond the standard text.

### Value type

* String or table - you can specify a single text string that will be used for all use cases, or you can specify different strings for each use case. See the examples below.

### Supported objectives

|Objective|How it's used
|-|-
|**[emote](../objectives/emote.md)**|Custom display text
|**[explore](../objectives/explore.md)**|Custom display text
|**[kill](../objectives/kill.md)**|Custom display text
|**[talkto](../objectives/talkto.md)**|Custom display text

Custom display text can also be used with a [start and complete conditions](../startcomplete.md) as well as [quest requirements](../requirements.md).

### Usage notes

The text

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

You may also notice the use of `%z` in the text above. This will get populated with the value of `zone` when the text is displayed. Each objective supports a set of these variables for custom text to reduce the amount of repetition in your script - these variables will be listed throughout these help pages when applicable.