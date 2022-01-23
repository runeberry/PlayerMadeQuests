# item-rewards

<a href="../index.md"><sub>← Home</sub></a>

> _This page refers to items as they are used with [quest rewards](../guides/rewards.md). For items used in quest objectives, see [Item](../parameters/item.md)._

The **item** parameter of a quest reward allows you to specify one or more items that will be rewarded upon completion of a quest. You can also declare that a player must **choose** one item from the list rather than receive all of them - see [Rewards](../guides/rewards.md) for more info.

## Value type

* String - the name of the item as it appears in game, along with an optional quantity

```yaml
# Single item
  item: Traveler's Jerkin
# Single item with quantity
  item: 20 Major Mana Potion
# Multiple items
  item:
    - Flimsy Chain Gloves
    - Flimsy Chain Bracers
    - Flimsy Chain Pants
# Multiple items, some with quantity
  item:
    - Flimsy Chain Gloves
    - 5 Minor Healing Potion
    - 10 Minor Mana Potion
```

* Table - with the either "id" or "name" and, optionally, "quantity"

```yaml
# Single item
  item:
    - id: 19019
# Single item with quantity
  item:
    - name: Nature Protection Potion
      quantity: 5
# Multiple items
  item:
    - id: 2153
    - id: 2154
    - id: 2155
# Multiple items, some with quantity
  item:
    - name: Major Healing Potion
    - name: Major Mana Potion
      quantity: 20
    - id: 2180
      quantity: 5
```

## Getting items by name

PMQ requires that all item names must be valid in-game item names so that the icon, tooltip, etc. can be retrieving using the WoW API. However, one of the limitation of the WoW API is that some of this information cannot be retrieved by name unless you have **encountered that item during your current game session**, meaning you've seen that item in your bags, bank, etc. PMQ adds an extra layer of functionality so that items that you have encountered will be written to a save file shared by all of your characters - meaning that if you encounter an item once on any character, you can then refer to it by name on all characters as, even between sessions.

But because it's not a perfect system, you may run into issues when trying to set an item reward by name that you don't actually own. There are, however, some ways to work around this:

* If possible, simply obtain the item and hover over it in your bags. You should now be able to refer to this item by name.
* Search for the item on [Wowhead](https://classic.wowhead.com/) and grab the item's ID from the URL, such as `item=1234`, where 1234 is the ID. Then, do one of two things:
  * Use the item by ID in your quest, following the examples above
  * Use the chat command `/pmq lookup-item 1234`, where 1234 is your item ID. If this is a valid item ID, then the item will be linked back to you, and you can now refer to this item by name in any quest you write.
* If you want to avoid this problem in the future, run the command `/pmq scan-items`. This kicks off a process that will check for **every known item ID in the game** and cache them all for future use in any quest draft on any character. However this takes about 20 minutes to run (for an estimated 25k items in Classic) and will be interrupted if you log out or `/reload` your UI. This process is throttled so you won't suffer any performance issues or get kicked offline as a result of scanning for items.
