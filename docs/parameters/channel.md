# channel

The **channel** parameter allows you to specify the channel through which a [message](../parameters/message.md) must be sent in order to satisfy an objective.

### Value type

* String - the name of the channel. The following values are supported:
  * say
  * yell
  * guild
  * raid
  * party
  * whisper

### Supported objectives

| Objective | How it's used |
|---|---|
| [say](../objectives/say.md) | The channel(s) in which you can send the message to complete the objective |

### Usage notes

* The value for channel is case-insensitive, meaning both "yell" and "YELL" will work.
* You can specify multiple channels, which means that sending the message in *any one* of these channels will satisfy the objective. For example:

```yaml
objectives:
  - say:
      message: "wash yer back"
      channel: [ say, yell ] # You can either /say or /yell this message
```
