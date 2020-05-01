# QuestScript Examples

Note that this reflects the target state of PMQ. Not all of the features below can be done with the addon yet, but are very much possible and planned for a future release.

Note that Rule names (`kill`, `talkto`, etc.) and Condition names (`t`, `target`, etc.) are case-insensitive. However, Condition values (`Mangy Wolf`, `Stormwind Guard`, etc.) _are_ case-sensitive.

Also note that quotes are only required when a Condition value contains spaces. Both single and double quotes are allowed.

```
kill 2 t="Mangy Wolf"
```

* "Kill 2 Mangy Wolves"
* Rule: `kill`
* Goal: 2
* Condition: Killed unit must be a Mangy Wolf

```
kill 5 t=Cow i="Greater Healing Potion" e="Forest Leather Belt"
```

* "Kill 5 Cows while having a Greater Healing Potion in your inventory and a Forest Leather Belt equipped"
* Rule: `kill`
* Goal: 5
* Conditions:
  * Kill unit must be a Cow
  * Inventory must have a Greater Healing Potion
  * Must have a Forest Leather Belt equipped

```
TalkTo t=Rexxar z=Feralas
```

* "Talk to Rexxar in Feralas"
* Rule: `talkto`
* Goal: 1 (goal of 1 is default, unless otherwise defined)
* Conditions:
  * Targeted unit must be Rexxar
  * Must be in the zone Feralas

```
emote em=hug t=Chepi a="Rallying Cry of the Dragonslayer"
```

* "Hug Chepi while you have the Ony buff"
* Rule: `emote`
* Goal: 1
* Conditions:
  * Emote must be `/hug`
  * Targeted unit must be Chepi
  * Must have the buff "Rallying Cry of the Dragonslayer"