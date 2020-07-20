[← Back to Quests](index.md)

# YAML Crash Course

**YAML** (which stands for "YAML Ain't Markup Language" - yes, really) is a simple language intended for writing configuration files that can be easily read and understood by humans, but also easily parsed by computers. This guide will give you a brief rundown on everything you need to know about YAML to write quests in PMQ.

### Properties and values

```yaml
name: Ragnaros    # this is a string - a line of text, can optionally be surrounded with quotes
level: 63         # this is a number - can also include decimals
spicy: true       # this is a boolean - can be true or false
```

In this example, we have a simple YAML document with 3 properties: `name`, `level`, and `spicy` - each with a value assigned.

In addition, everything after a `#` character is a comment, which means it will not be interpreted as YAML. I've added some comments explaining what type each value is.

### Block indentation

```yaml
name: Malfurion
pet: # the "pet" block has 4 properties
  name: Tricky
  species: Raptor
  colors: # the "colors" block has 2 properties
    hide: red
    feathers: green
  level: 35
# Simple blocks can also be written on one line (flow-style)
pet: { name: Tricky, species: Raptor, level: 35 }
```

You can nest properties inside other properties to form a block. This is achieved by simply indenting a line more. It doesn't matter how much you indent the line, as long as you are consistent throughout your YAML document. We recommend indenting with 2 or 4 spaces per level.

### Sequences

```yaml
name: Malfurion
# Sequence with one item per line
pets:
  - Tricky
  - Beedle
  - Midna
# Sequence with all items on one line (flow-style)
pets: [ Tricky, Beedle, Midna ]
```

You can assign multiple values to a property by adding a `-` before each value. Each item in a sequence can be a simple type (string, number, or boolean) or another block of properties, which you will see when writing quest objectives:

```yaml
objectives:
  - kill 5 Chicken
  - explore:
      zone: Elwynn Forest
      subzone: Goldshire
```

### More information

* [YAML cheatsheet](https://cheat.readthedocs.io/en/latest/yaml.html) - a short cheatsheet with just the basics of YAML.
* [lua-tinyyaml](https://github.com/peposso/lua-tinyyaml) - the YAML parser library used in PMQ. Not all features of YAML are supported by this library, so you may want to poke around here if you're trying to use more advanced YAML features and they're not working.