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
      target: Murloc Steamrunner
      goal: 2
      zone: Crystal Lake
      coords: 50.57,66.80]],
  [2] = [[
objectives:
  - kill Cow
  - kill 2 'Forest Spider'
  - kill 3 "Mangy Wolf"]],
  [3] = [[
objectives:
  - talkto: { target: Erma }
  - talkto: { target: Stormwind Guard, goal: 2 }
  - talkto:
      target: Marshal Dughan
      aura: Blessing of Might
  - talkto:
      target: Chicken
      goal: 2
      zone: Elwynn Forest
      subzone: Goldshire]],
  [4] = [[
objectives:
  - talkto Erma
  - talkto 'Marshal Dughan'
  - talkto 2 "Stormwind Guard"
  - talk "Stonetusk Boar"
  - talk 2 Chicken]],
  [5] = [[
objectives:
  - emote: { emote: dance }
  - emote: { emote: laugh, target: Erma }
  - emote:
      emote: flirt
      target: Marshal Dughan
  - emote:
      emote: fart
      goal: 2
      target: Stormwind Guard
  - emote:
      emote: roar
      aura: Blessing of Might
  - emote:
      emote: dance
      goal: 2
      target: Stormwind Guard
      aura: Blessing of Might
  - emote:
      emote: chicken
      target: Chicken
      goal: 2
      zone: Elwynn Forest
      subzone: Goldshire
  - emote:
      emote: sigh
      target: Murloc Steamrunner
      zone: Crystal Lake
      coords: 50.57,66.80]],
  [6] = [[
objectives:
  - emote dance
  - emote laugh Erma
  - emote flirt 'Marshal Dughan'
  - emote fart 2 "Stormwind Guard"]],
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
      aura: Blessing of Might]],
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
  - getaura:
      aura: Blessing of Might
  - getaura:
      aura: Blessing of Might
      zone: Elwynn Forest
      subzone: Goldshire
      coords: 42.41, 64.47, 0.3
  - getaura: { aura: Blessing of Might, zone: Lion's Pride Inn }]],
  [10] = [[
objectives:
  - getaura 'Blessing of Might']],
}

addon.DebugQuestDB = {
  {
    name = "Objective: aura",
    script = scripts[9],
  },
  {
    name = "Objective: aura (shorthand)",
    script = scripts[10],
  },
  {
    name = "Objective: emote",
    script = scripts[5],
  },
  {
    name = "Objective: emote (shorthand)",
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
    name = "Objective: talkto",
    script = scripts[3],
  },
  {
    name = "Objective: talkto (shorthand)",
    script = scripts[4],
  },
}

for i, quest in ipairs(addon.DebugQuestDB) do
  quest.debugQuestId = "debug-quest-"..quest.name
  quest.order = i
end