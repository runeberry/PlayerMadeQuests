# message

The **message** parameter allows you to specify a phrase or pattern that must be spoken by the player in order to complete an objective.

### Value type

* String - the phrase or pattern that the player must say.

The full range of [Lua patterns](https://riptutorial.com/lua/example/20315/lua-pattern-matching) are supported for this parameter, but you can use the following examples to get started.

Note that all values for message are **case-insensitive**, meaning that "happy birthday" and "Happy Birthday" would both work in the first example.

| Value | Result |
|---|---|
| "happy birthday" | The message must contain the phrase "happy birthday" somewhere inside it |
| "^happy b" | The message must start with the phrase "happy b" |
| "birthday$" | The message must end with the word "birthday" |
| "^happy bar mitzvah!$" | The message must be exactly the phrase "happy bar mitzvah | " with nothing else before or after it |

### Supported objectives

| Objective | How it's used |
|---|---|
| [[say]] | The message which the player must say in order to complete the objective |

### Usage notes

* While Lua patterns are case-sensitive, the value for this message parameter is intentionally **not case-sensitive**, meaning that you cannot force a player to say something in a specific casing style. For example, if you specify the pattern "Happy Birthday", then a player will be able to say "happy birthday" to satisfy the condition. As such, it's recommended to keep your patterns for message to all lowercase letters, for simplicity.
* It can be somewhat tedious to test complex message patterns in-game, so until there is a better testing method included with PMQ, consider using this [Online Lua Compiler](https://rextester.com/l/lua_online_compiler) to test which phrases will or will not work with your message pattern. Simply copy/paste the following code into the editor linked, and click **Run it (F8)** to print the results below the code editor. Of course, you'll want to change out the pattern and chat messages in the below code to suit your needs.

```lua
-- Change this pattern to the "message" pattern value you want to test
local pattern = "nothing %w-, nothing %w-"

local function testPattern(message)
  local result
  if string.match(message, pattern) then
    result = "[PASS]" -- This chat message would pass the objective
  else
    result = "[FAIL]" -- This chat message would NOT pass the objective
  end
  print(result, message)
end

-- Test any chat messages you want to test against the pattern
testPattern("nothing ventured, nothing gained")
testPattern("nothing spent, nothing saved")
testPattern("this message should not pass")
```
