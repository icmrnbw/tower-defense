# Tower art

Hand-authored vector sprites that follow `docs/art/tower-prompts.md` (style prefix + level progression rules).

- `towers/<id>/svg/tower_<id>_<state>.svg` — source vectors, scale to any size.
- `towers/<id>/png/tower_<id>_<state>.png` — 512x512, transparent background.
- `previews/<id>_sheet.png` — review sheet (row 1: L1-L3, row 2: branch A L4/L5, row 3: branch B L4/L5).
- `src/` — generator. Rebuild with:
  `cd src && PLAYWRIGHT_MODULE=$NODE_PATH/playwright python3 build.py bolt`

Conventions: 3/4 top-down view, light from top-left, outline `#1c1724`, shared stone pad (`common.pad()`),
pivot at (256, 372). Turret heads aim 35° clockwise from up; `build(state, with_pad=False)` drops the pad.
