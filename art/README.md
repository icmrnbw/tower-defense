# Tower art

Hand-authored vector sprites that follow `docs/art/tower-prompts.md` (style prefix + level progression rules).

- `towers/<id>/svg/tower_<id>_<state>.svg` — source vectors, scale to any size.
- `towers/<id>/png/tower_<id>_<state>.png` — 512x512, transparent background.
- `previews/<id>_sheet.png` — review sheet (row 1: L1-L3, row 2: branch A L4/L5, row 3: branch B L4/L5).
- `src/` — generator. Rebuild with:
  `cd src && PLAYWRIGHT_MODULE=$NODE_PATH/playwright python3 build.py bolt`

Conventions: 3/4 top-down view, light from top-left, outline `#1c1724`, shared stone pad (`common.pad()`),
pivot at (256, 372). Turret heads aim 35° clockwise from up; `build(state, with_pad=False)` drops the pad.

## Animated parts

- `src/bolt_parts.py` splits the Bolt Turret into `game/art/towers/bolt/parts/` (base, turret, loaded bolt + bow geometry in `parts.json`). The game rotates the turret and draws the bow limbs and string in code.

## Monsters

Side-view rigged creatures, facing right, feet at (0, 0). `src/monster_kit.py` has the shape kit (gradients, rim light, painterly noise, glowing eyes) and the build: each part is rendered with headless Chromium, trimmed and packed with a white silhouette copy into `game/art/monsters/<id>.png` + `<id>.json` (pivots, parents, animation specs).

- Designs: `src/monsters_humanoid.py` (goblin, imp, orc, hobgoblin, shaman, troll, ogre, pharaoh) and `src/monsters_beasts.py` (warg, void_hound, bat, wyvern, dragon, wraith, frost_wraith, lich, worm, sandwyrm, wagon, beetle, thornback, ice_golem, clockwork).
- Build: `cd src && PLAYWRIGHT_MODULE=$NODE_PATH/playwright python3 monsters.py [id ...]`
- Review sheet: `python3 monster_sheet.py /tmp/sheet.png [id ...]`
- `enemies.json` maps each enemy to a design with its `art` key.
