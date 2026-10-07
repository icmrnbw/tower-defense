# Bastion Lanes (working title)

A 2D arcade tower defense game for Android / Google Play, built with **Godot 4.4** (GDScript).

- Design: [docs/GDD.md](docs/GDD.md)
- Tower art prompts: [docs/art/tower-prompts.md](docs/art/tower-prompts.md)
- Game project: [`game/`](game/) (open `game/project.godot` in Godot 4.4+)

## Current state: vertical slice (step 2 of 4)

One level, *Verdant Crossing*: a forked lane plus an air route, 12 build pads, 12 waves ending in the **Iron Beetle** boss (armored, periodically hardens its shell).

- 3 towers with 5 levels each and a branch choice at level 4:
  - **Bolt Turret** (Gatling or Piercer)
  - **Cannon** (Cluster Bombard or Siege Howitzer)
  - **Frost Spire** (Glacier Heart or Blizzard Engine)
- 5 enemies + boss: Scuttler, Runner, Swarmling, Brute (armored), Drone (flying)
- Gold, lives, 1 to 3 stars, early wave call bonus, sell refunds, targeting modes (First/Last/Strong/Weak/Closest), x1/x2/x3 speed, pause
- Touch-first HUD: tap a pad to build, tap a tower to upgrade/branch/sell
- Placeholder art is drawn in code; sprites from `art/` replace it in step 3

## Where things live

| Path | What |
|---|---|
| `game/data/towers.json` | All tower stats per level/branch. Balance here, no code changes needed |
| `game/data/enemies.json` | Enemy stats |
| `game/data/levels/*.json` | Level layout (paths, air paths, pads) and waves |
| `game/scripts/game.gd` | Level runner: waves, economy, building, input, map drawing |
| `game/scripts/tower.gd`, `enemy.gd`, `projectile.gd`, `fx.gd` | Gameplay objects |
| `game/scripts/hud.gd` | UI |
| `game/scripts/bot.gd` | Headless test player |

## Running

Open `game/project.godot` in Godot 4.4 and press Play.

Headless playtest (a bot plays the level and prints the outcome):

```
GODOT=/path/to/godot game/tests/run_autotest.sh basic   # scripted build order, currently wins with 1 star
GODOT=/path/to/godot game/tests/run_autotest.sh none    # builds nothing, must lose
```

Note for Android export (step 4): JSON files are not resources, so the export preset must include `*.json` in "Filters to export non-resource files".
