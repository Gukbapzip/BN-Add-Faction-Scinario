# NC Hostile Factions

A faction test mod for Cataclysm: Bright Nights. It replaces selected NPC and monster populations with hostile factions.

## Installation

1. Place `nc_hostile_factions` in the game's `mods` folder.
2. Enable `NC Hostile Factions` when creating a world.
3. Start a new world, or explore map tiles that have not generated before.

Generated areas are not retroactively changed in existing saves.

## Factions

| Faction | Location | Population | Equipment and abilities |
| --- | --- | --- | --- |
| `nc_rebels` | Military base | Large patrol force, 7 tower snipers, 1 `mon_mech_recon`, 1 power-armor boss | Specialist militia use advanced 4–8 skills, custom tactical armor, machine guns, sniper rifles, and military equipment. All base monsters are removed outside the minefield. |
| `nc_sanitizers` | Standard hospitals | 2–4, 80% chance per eligible tile | Standard, heavy, and marksman variants. All use hazmat or ANBC suits and flamethrowers. Stronger than Cyborgs. |
| `nc_cyborgs` | Augmentation clinic levels `n1`–`n3` | 10 across the clinic | Advanced CBMs, alloy plating, targeting, speed, defensive bionics, bionic melee weapons, or military-grade guns. |
| `nc_mutated_scientists` | Microlabs, including `4x4_microlab` | 4, 35% chance per eligible tile | Stronger than Sanitizers. Randomized strength, melee, toughness, and size mutations. Mostly unarmed or using poor lab tools. |
| `nc_biker_gang` | Gas stations | 3–5 | Random handguns, SMG, sawed-off shotgun, machete, or bat. Each biker has a pristine Superbike and a full steel jerrycan. |
| `nc_tunnel_rats` | Subway stations | 3–12, 20% chance per station tile | Mouse, Spider, or Troglobite threshold, night vision, cannibalism, crossbows, and knives. Normally neutral unless provoked; low-value salvage drops. |
| `nc_flesh_cult` | Underground mines | 1–3, 70% chance per mine tile | Chimera threshold, minor CBMs, poor melee weapons, and a small mutagen/CBM loot reward. Stronger individually than a Tunnel Rat. |

## Threat Order

1. NC Rebels — endgame faction.
2. NC Mutated Scientists.
3. NC Sanitizers.
4. NC Cyborgs.
5. NC Flesh Cultists.
6. NC Bikers.
7. NC Tunnel Rats — weakest individually and generally neutral.

All factions are hostile to the player.

## Skill Scale

- `2`: Basic.
- `4`: Normal.
- `6`: Advanced.
- `8`: Maximum non-player skill.

No faction NPC has a skill above 8.
