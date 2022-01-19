# say

The **say** objective is triggered whenever you send a message to a chat channel. This objective requires you to send a message that meets a message containing a certain phrase, along with meeting any of the conditions outlined below.

### Shorthand

```yaml
objectives:
  - say "message*"
```

_*required_

Note that this shorthand form is not recommended for real quest objectives, only for quickly testing phrases. Use the long form better quest objectives.

### Long form

```yaml
objectives:
  - say:
      message: "my secret message" # Required. Quotes are optional, but recommended.
      language: Dwarvish
      channel: yell
      target: Questborther # A player's name to whisper
      zone: Elwynn Forest
      subzone: Goldshire
      coords: 42.41, 64.47, 0.3
      aura: "Power Word: Fortitude"
      equip: Loose Chain Mail
      item: Light Leather
      text: "Custom display text"
```

### Supported parameters

| Parameter | How it's used |
|---|---|
| [aura](../parameters/aura.md) | The name of the aura you must have when saying the message |
| [channel](../parameters/channel.md) | The channel(s) you must say the message through (see linked page for options) |
| [equip](../parameters/equip.md) | An item you must have equipped when saying the message |
| [item](../parameters/item.md) | An item you must have in your bags when saying the message |
| [language](../parameters/language.md) | The RP language(s) that the message must be spoken in |
| [message](../parameters/message.md) | The phrase or pattern that must be present within the message |
| [recipient](../parameters/recipient.md) | The name of the player(s) you must send the message to (only applicable to whispers) |
| [text](../parameters/text.md) | Custom display text for this objective |
| [zone](../parameters/zone.md)<br/>[subzone](../parameters/zone.md)<br/>[coords](../parameters/coords.md) | The location you must be in when saying the message |

### Examples

#### Secret messages

You will likely want to change the default display text of the objective so that it doesn't reveal the exact text that the player should speak in order to progress. Consider the following example:

```yaml
objectives:
  - say:
      text: "Speak, friend, and enter."
      message: "mellon"
      channel: [ say, yell ]
      zone: Moria
      subzone: Doors of Durin
      coords: 38.7, 42.5, 0.1
```

In this hypothetical example, the player would need to /say or /yell a message with the phrase "mellon", while standing in front of the Doors of Durin, in order to progress the quest objective. However, the quest log would simply read the riddle: "Speak, friend, and enter."

Note that this will print the same text to the quest log, quest info frame, and quest progress message (the yellow text that pops up when you progress). See the [Display text](../parameters/text.md) page for details on how to configure these individually.

Here's another take on this old classic:

```yaml
objectives:
  - say:
      text: "Speak, friend, and enter."
      message: "^friend$"
      language: Dwarvish
      channel: [ say, yell ]
```

In this example, the player would need to /say or /yell exactly the word "friend" (see the) while speaking in the Dwarvish [language](../parameters/language.md) in-game. Saying "friend" in Common or any other language would not complete the objective.
