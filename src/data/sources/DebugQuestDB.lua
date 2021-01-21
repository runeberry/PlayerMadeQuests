local _, addon = ...

local scripts = {
  [1] = [[
objectives:
  - kill: { target: Cow }
  - kill: { target: Mangy Wolf, goal: 3 }
  - kill:
      target: Chicken
      goal: 2
      zone: Elwynn Forest
      subzone: Goldshire
  - kill:
      target: Stonetusk Boar
      goal: 2
      aura: Blessing of Might
  - kill:
      target: Murloc
      goal: 2
      zone: Crystal Lake
      coords: 50.57,66.80
  - kill:
      target: Stonetusk Boar
      goal: 2
      item: Light Leather
  - kill:
      target: Cow
      equip: Knitted Belt]],
  [2] = [[
objectives:
  - kill Cow
  - kill 2 'Forest Spider'
  - kill 3 "Mangy Wolf"]],
  [3] = [[
objectives:
  - talk-to: { target: Erma }
  - talk-to: { target: Stormwind Guard, goal: 2 }
  - talk-to:
      target: Marshal Dughan
      aura: Blessing of Might
  - talk-to:
      target: Chicken
      goal: 2
      zone: Elwynn Forest
      subzone: Goldshire
  - talk-to:
      target: Innkeeper Farley
      item: Light Leather
  - talk-to:
      target: Smith Argus
      equip: Knitted Belt]],
  [4] = [[
objectives:
  - talk-to Erma
  - talk-to 'Marshal Dughan'
  - talk-to 2 "Stormwind Guard"
  - talk-to "Stonetusk Boar"
  - talk-to 2 Chicken]],
  [5] = [[
objectives:
  - use-emote: { emote: dance }
  - use-emote: { emote: laugh, target: Erma }
  - use-emote:
      emote: flirt
      target: Marshal Dughan
  - use-emote:
      emote: fart
      goal: 2
      target: Stormwind Guard
  - use-emote:
      emote: roar
      aura: Blessing of Might
  - use-emote:
      emote: dance
      goal: 2
      target: Stormwind Guard
      aura: Blessing of Might
  - use-emote:
      emote: chicken
      target: Chicken
      goal: 2
      zone: Elwynn Forest
      subzone: Goldshire
  - use-emote:
      emote: sigh
      target: Murloc
      zone: Crystal Lake
      coords: 50.57,66.80
  - use-emote:
      emote: growl
      target: Stonetusk Boar
      goal: 2
      item: Light Leather
  - use-emote:
      emote: golfclap
      target: Erma
      equip: Knitted Belt]],
  [6] = [[
objectives:
  - use-emote dance
  - use-emote laugh Erma
  - use-emote flirt 'Marshal Dughan'
  - use-emote fart 2 "Stormwind Guard"]],
  [7] = [[
objectives:
  - explore: { zone: Elwynn Forest }
  - explore: { zone: Elwynn Forest, subzone: Goldshire }
  - explore:
      zone: Elwynn Forest
      subzone: Goldshire
      coords: 42.41, 64.47, 0.1
  - explore:
      zone: Goldshire
      coords: 42.41,64.47,0.3
  - explore:
      zone: Lion's Pride Inn
  - explore:
      zone: Lion's Pride Inn
      aura: Blessing of Might
  - explore:
      zone: Goldshire
      coords: 42.41, 64.47
      aura: Blessing of Might
  - explore:
      zone: Goldshire
      coords: 42.41,64.47,0.3
      item: Light Leather
  - explore:
      zone: Goldshire
      coords: 42.08, 66.16, 0.1
      equip: Knitted Belt]],
  [8] = [[
objectives:
  - explore Goldshire
  - explore 'Elwynn Forest'
  - explore "Lion's Pride Inn"
  - explore Goldshire 42.41,64.47,0.1
  - explore 'Elwynn Forest' '42.41, 64.47, 0.3'
  - explore Goldshire 42.41,64.47
  - explore "Elwynn Forest" "42.41, 64.47, 1"]],
  [9] = [[
objectives:
  - gain-aura: { aura: Blessing of Might }
  - gain-aura:
      aura: Blessing of Might
      zone: Elwynn Forest
      subzone: Goldshire
      coords: 42.41, 64.47, 0.3
  - gain-aura: { aura: Blessing of Might, zone: Lion's Pride Inn }
  - gain-aura:
      aura: Blessing of Might
      item: Light Leather
  - gain-aura:
      aura: Blessing of Might
      equip: Knitted Belt]],
  [10] = [[
objectives:
  - gain-aura 'Blessing of Might']],
  [11] = [[
objectives:
  - equip-item: { equip: Knitted Belt },
  - equip-item:
      equip: Knitted Belt
      zone: Elwynn Forest
      subzone: Goldshire
      coords: 42.41, 64.47, 0.3
  - equip-item: { equip: Knitted Belt, zone: Lion's Pride Inn }
  - equip-item:
      equip: Knitted Belt
      item: Light Leather
  - equip-item:
      equip: Knitted Belt
      aura: Blessing of Might]],
  [12] = [[
objectives:
  - equip-item 'Knitted Belt']],
  [13] = [=[
objectives:
  - loot-item: { item: Linen Cloth },
  - loot-item: { goal: 3, item: Light Leather }
  - loot-item:
      goal: 3
      item: [ Light Leather, Ruined Pelt, Ruined Leather Scraps ]
  - loot-item:
      goal: 3
      item: [ Broken Boar Tusk, Chipped Boar Tusk ]
      zone: Elwynn Forest
      coords: 40,75,2
      text: Boar tusks @ field south of Goldshire %p/%g
  - loot-item:
      goal: 3
      item: [ Light Leather, Ruined Pelt, Ruined Leather Scraps ]]
      aura: Blessing of Might
      text: Leather products w/ %a %p/%g
  - loot-item:
      goal: 3
      item: [ Light Leather, Ruined Pelt, Ruined Leather Scraps ]]
      equip: Knitted Belt
      text: Leather products w/ %e %p/%g]=],
  [14] = [[
objectives:
  - loot-item 'Linen Cloth'
  - loot-item 3 'Light Leather']],
  [15] = [[
objectives:
  - cast-spell:
      spell: Fire Blast
  - cast-spell:
      spell: Fireball
      goal: 3
  - cast-spell:
      spell: Frostbolt
      goal: 5
      target: Stonetusk Boar
  - cast-spell:
      spell: Fireball
      goal: 3
      target: Stonetusk Boar]],
  [16] = [[
objectives:
  - cast-spell "Fire Blast"
  - cast-spell 3 Fireball
  - cast-spell 5 Frostbolt "Stonetusk Boar"]],
}

addon.DebugQuestDB = {
  {
    name = "Objective: gain-aura",
    script = scripts[9],
  },
  {
    name = "Objective: gain-aura (shorthand)",
    script = scripts[10],
  },
  {
    name = "Objective: use-emote",
    script = scripts[5],
  },
  {
    name = "Objective: use-emote (shorthand)",
    script = scripts[6],
  },
  {
    name = "Objective: explore",
    script = scripts[7],
  },
  {
    name = "Objective: explore (shorthand)",
    script = scripts[8],
  },
  {
    name = "Objective: kill",
    script = scripts[1],
  },
  {
    name = "Objective: kill (shorthand)",
    script = scripts[2],
  },
  {
    name = "Objective: talk-to",
    script = scripts[3],
  },
  {
    name = "Objective: talk-to (shorthand)",
    script = scripts[4],
  },
  {
    name = "Objective: equip-item",
    script = scripts[11],
  },
  {
    name = "Objective: equip-item (shorthand)",
    script = scripts[12],
  },
  {
    name = "Objective: loot-item",
    script = scripts[13],
  },
  {
    name = "Objective: loot-item (shorthand)",
    script = scripts[14],
  },
  {
    name = "Objective: cast-spell",
    script = scripts[15],
  },
  {
    name = "Objective: cast-spell (shorthand)",
    script = scripts[16],
  },
}

for i, quest in ipairs(addon.DebugQuestDB) do
  quest.order = i
  quest.questId = "debug-quest-"..quest.name
  quest.parameters = {
    questId = quest.questId,
    name = quest.name,
  }
end