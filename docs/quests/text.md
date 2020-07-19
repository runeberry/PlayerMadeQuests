[← Back to Quests](index.md)

# Custom display text

PMQ is designed to automatically interpret your quest information and display it back to players in a nice, readable way whenever possible.

However, there are some cases in your quest where you may want to display custom text, such as when listing quest objectives to players. In these cases, you can use the `text` parameter, which can be added to your quest as follows:

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

## Supported use cases

PMQ supports the `text` parameter in the following parts of QuestScript:

* All [quest objectives](objectives/index.md)
* The [start & complete](startcomplete.md) objectives