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
      item: Light Leather]],
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
      item: Light Leather]],
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
      item: Light Leather]],
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
      item: Light Leather]],
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
  - gain-aura:
      aura: Blessing of Might
  - gain-aura:
      aura: Blessing of Might
      zone: Elwynn Forest
      subzone: Goldshire
      coords: 42.41, 64.47, 0.3
  - gain-aura: { aura: Blessing of Might, zone: Lion's Pride Inn }
  - gain-aura:
      aura: Blessing of Might
      item: Light Leather]],
  [10] = [[
objectives:
  - gain-aura 'Blessing of Might']],
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
}

for i, quest in ipairs(addon.DebugQuestDB) do
  quest.order = i
  quest.questId = "debug-quest-"..quest.name
  quest.parameters = {
    questId = quest.questId,
    name = quest.name,
  }
end