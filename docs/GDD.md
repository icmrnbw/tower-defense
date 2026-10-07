# Tower Defense: Game Design Document (v0.1 draft)

Working title: **Bastion Lanes** (placeholder, rename freely)
Engine: Godot 4 (GDScript) · Target: Android / Google Play, portrait-free landscape, phones first
Style: 2D arcade, top-down 3/4 view, bold outlines, saturated colors, punchy VFX

---

## 1. Design pillars

1. **Tactics over grinding.** Every level is beatable at 3 stars without meta upgrades if you build smart. Enemy mixes are chosen so no single tower solves a world.
2. **Readable chaos.** Lots of things explode, but silhouettes, colors and damage numbers always tell you what is happening.
3. **Towers you get attached to.** 10 towers, each with 5 levels and a branch choice at level 4, and visuals that get dramatically cooler while staying recognisable.
4. **Short sessions.** A level takes 4 to 8 minutes. Fast-forward (x2, x3) is always available.

---

## 2. Core loop

1. Pick a level on the world map (stars gate the next world).
2. Pre-battle: see the enemy preview (which enemy types will appear) and pick up to 6 towers for your loadout (from level 11 on; before that all unlocked towers are available).
3. Battle: build on **build slots**, upgrade, sell, call waves early, use the hero ability (see 6.4).
4. Result: 1 to 3 stars by lives left (3 stars = 18+ of 20 lives, 2 = 10+, 1 = survived).
5. Earn **Crystals** (stars + first clear bonuses) and spend them in the Research tree (6.5).

---

## 3. Economy and rules (where the tactics come from)

| Rule | Value | Why it matters |
|---|---|---|
| Starting gold | Per level, 250 to 600 | Tight openings force a decision on wave 1 |
| Gold per kill | Per enemy type (see 5) | Killing fast enemies early pays more |
| Early wave call | Bonus gold = seconds remaining x 2 | Rewards confident players, risky |
| Sell refund | 70% of total spent (100% if sold in the same wave it was built) | Lets players fix mistakes but punishes flip-flopping |
| Build slots | Fixed pads per map, 8 to 22 | Placement is the puzzle; not every pad covers every lane |
| Lives | 20 per level; normal enemy = 1, elite = 3, boss = 10 | One leaked boss can cost a star |
| Loadout | Max 6 tower types per level (from level 11) | Forces counter-picking from the enemy preview |
| Targeting | First, Last, Strong, Weak, Closest, Air-first | Per-tower toggle, a key skill expression |

### Damage types and defences

| Damage type | Towers | Strong against | Weak against |
|---|---|---|---|
| Physical | Bolt, Cannon, Railgun, Missile | Unarmored, Shielded | **Armored** (-50%) |
| Energy | Tesla, Prism | Armored | **Shielded** (shield soaks energy at 2x efficiency) |
| Elemental (Fire, Frost, Poison) | Inferno, Frost Spire, Venom Spore | Regenerators (fire/poison stop regen) | **Elemental-resistant** enemies per world |

Status effects: Slow, Freeze, Burn, Poison (stacks), Armor Shred, Stun, Reveal (makes stealth targetable).
Bosses take 50% duration from crowd control and are immune to Freeze and instakill.

---

## 4. Towers

10 towers. Each has **5 levels**. At **level 4** the player chooses **Branch A or Branch B**, which continues to level 5. That gives 7 visual states per tower: L1, L2, L3, L4A, L5A, L4B, L5B.

Upgrade cost relative to build cost: L2 = 0.75x, L3 = 1.0x, L4 = 1.6x, L5 = 2.5x.
Damage roughly x1.5 per level; range +10% at L3 and L5.

| # | Tower | Role | Dmg type | Targets | Cost | Unlock |
|---|---|---|---|---|---|---|
| 1 | **Bolt Turret** | Cheap fast single-target DPS | Physical | Ground + Air | 100 | Level 1 |
| 2 | **Cannon** | Splash vs groups, min range | Physical | Ground | 150 | Level 1 |
| 3 | **Frost Spire** | Slow / control | Frost | Ground | 130 | Level 3 |
| 4 | **Tesla Coil** | Chain lightning, anti-armor | Energy | Ground + Air | 180 | Level 6 |
| 5 | **Railgun** | Extreme range, armor pierce | Physical | Ground + Air | 220 | Level 9 |
| 6 | **Inferno** | Short cone, burn, anti-regen | Fire | Ground | 170 | Level 12 |
| 7 | **Skyhunter** | Homing missiles, anti-air | Physical | Air (B: both) | 200 | Level 15 |
| 8 | **Venom Spore** | Poison stacks, armor shred | Poison | Ground | 160 | Level 19 |
| 9 | **Amplifier** | Support aura, reveals stealth, no attack | none | n/a | 250 | Level 23 |
| 10 | **Prism Laser** | Ramping beam, boss killer | Energy | Ground + Air | 300 | Level 31 |

### Branches

| Tower | Branch A | Branch B |
|---|---|---|
| Bolt Turret | **Gatling**: 3x fire rate, lower damage per shot | **Piercer**: bolts pass through up to 4 enemies |
| Cannon | **Cluster Bombard**: shells split into 5 bomblets | **Siege Howitzer**: huge range, single massive shell, 0.5s stun |
| Frost Spire | **Glacier Heart**: freezes solid; frozen enemies take +40% damage (shatter) | **Blizzard Engine**: big radius slow, also slows air |
| Tesla Coil | **Storm Conductor**: +4 chains, arcs between nearby Teslas | **Overload**: slow massive discharge that strips shields instantly |
| Railgun | **Deadeye**: 30% crit for 3x, reveals stealth in range | **Executioner**: instantly kills non-boss enemies under 15% HP, +5% boss max-HP damage |
| Inferno | **Dragon Maw**: long cone, burning enemies spread fire on death | **Magma Forge**: leaves lava pools on the path |
| Skyhunter | **Swarm Battery**: 8 mini missiles per volley | **Thunderhead**: one heavy missile, big splash, hits ground too |
| Venom Spore | **Plague Garden**: poison spreads to nearby enemies on death | **Acid Geyser**: heavy armor shred (-60% armor), puddles |
| Amplifier | **War Totem**: +25% fire rate, +10% crit to towers in radius | **Treasury Beacon**: +50% gold from kills in radius |
| Prism Laser | **Solar Lance**: beam pierces everything in a line | **Singularity Focus**: ramps 2x faster, much higher cap, single target |

Exact numbers live in `data/towers.json` (created in step 2) so balancing never needs code changes.

---

## 5. Enemies

| Enemy | Trait | HP (base) | Speed | Gold | First seen |
|---|---|---|---|---|---|
| Scuttler | Basic | 40 | 1.0 | 4 | 1 |
| Runner | Fast, fragile | 25 | 2.0 | 5 | 2 |
| Swarmling | Comes in packs of 10 to 20, tiny | 8 | 1.4 | 1 | 4 |
| Brute | **Armored** | 160 | 0.7 | 12 | 5 |
| Drone | **Flying**, ignores path, flies straight to exit | 35 | 1.3 | 6 | 7 |
| Shieldbearer | **Shielded**, projects shield on neighbours | 90 + 60 shield | 0.9 | 10 | 11 |
| Mender | Heals nearby enemies 5%/s | 70 | 0.9 | 10 | 14 |
| Splitter | Splits into 3 Scuttlers on death | 120 | 0.9 | 8 | 17 |
| Regenerator | Regenerates 4%/s unless burning or poisoned | 140 | 0.8 | 12 | 21 |
| Phantom | **Stealth**, only targetable when revealed | 80 | 1.2 | 12 | 24 |
| Gunship | Flying + Armored | 220 | 0.8 | 18 | 27 |
| Burrower | Dives underground for 3s every 6s (untargetable) | 180 | 1.0 | 14 | 33 |
| Warden | Elite: armored + shielded, spawns Swarmlings | 600 | 0.6 | 40 | 38 |

Enemy HP scaling: `hp = base * (1 + 0.09 * (level - 1)) * (1 + 0.04 * (wave - 1))`.
Each world also gives some enemies a world resistance (World 2: fire-resistant, World 3: frost-resistant) so players must re-think favourite builds.

### Bosses

Mini-boss on every level ending in 5, world boss on every level ending in 0.

| Level | Boss | Gimmick (what tactic it tests) |
|---|---|---|
| 5 | **Iron Beetle** (mini) | Very armored: teaches Cannon/Bolt aren't enough, slows help |
| 10 | **Thornback Behemoth** | Sheds armor plates at 66% and 33% HP and speeds up: hold burst for the end |
| 15 | **Sandwyrm** (mini) | Burrows and resurfaces further down the path: needs coverage depth |
| 20 | **Pharaoh Colossus** | Summons Shieldbearers, reflects fire: needs Energy damage and target priority |
| 25 | **Frost Wraith** (mini) | Stealth + freezes nearest tower for 3s: needs reveal and spread-out builds |
| 30 | **Glacier Titan** | Immune to slow; splits into 2 then 4 smaller titans: needs splash late |
| 35 | **Overclock Mech** (mini) | Disables towers in a radius every 10s (EMP): spread defences across the lane |
| 40 | **Foundry Dreadnought** | Flying carrier that drops Brutes on the path: needs anti-air and ground |
| 45 | **Rift Stalker** (mini) | Teleports between lanes: needs flexible coverage |
| 50 | **The Void Sovereign** | 3 phases: shielded, then flying, then splits the path and spawns Wardens |

---

## 6. Levels and worlds

5 worlds x 10 levels. Each world has its own tileset, music, lane mechanic and resistant enemy.

| World | Levels | Theme | Lane mechanic | Visual palette |
|---|---|---|---|---|
| 1. Verdant Vale | 1 to 10 | Rolling fields, ruins | Basic single lanes, then forks | Greens, warm stone |
| 2. Scorched Dunes | 11 to 20 | Desert, temples | **Sandstorms** shrink tower range by 30% for 10s | Ochre, terracotta, teal accents |
| 3. Frostpeak | 21 to 30 | Glaciers, ice caves | **Ice paths** make enemies 40% faster on some tiles | Ice blue, white, violet |
| 4. Neon Foundry | 31 to 40 | Industrial cyber city | **Power nodes**: pads on nodes get +25% damage; conveyors move enemies | Dark steel, neon magenta and cyan |
| 5. Void Rift | 41 to 50 | Cosmic floating islands | **Rifts** teleport enemies between lanes | Deep purple, gold, black |

### Level list

Lane layouts: **S** = single lane, **F** = fork (splits and rejoins), **M** = multiple spawns merge, **P** = parallel separate lanes, **X** = crossing lanes, **L** = long winding loop, **A** = air route.

| # | Layout | Waves | Focus / new element |
|---|---|---|---|
| 1 | S | 6 | Tutorial: build Bolt |
| 2 | S | 8 | Runners, targeting priority |
| 3 | L | 8 | Frost Spire unlocked |
| 4 | S | 10 | Swarmlings, Cannon value |
| 5 | F | 10 | **Iron Beetle**, Brutes |
| 6 | F | 12 | Tesla unlocked vs armor |
| 7 | S + A | 12 | Drones (air) |
| 8 | M | 12 | Two spawns |
| 9 | X | 14 | Railgun unlocked, crossing lanes reward central pads |
| 10 | F + A | 15 | **Thornback Behemoth** |
| 11 | L | 12 | Loadout of 6 begins; Shieldbearers |
| 12 | S | 12 | Inferno unlocked; sandstorms |
| 13 | F | 14 | Fire-resistant variants |
| 14 | M | 14 | Menders, priority targeting |
| 15 | P | 15 | **Sandwyrm**; Skyhunter unlocked |
| 16 | X + A | 15 | Heavy air waves |
| 17 | F | 15 | Splitters |
| 18 | L | 16 | Limited pads (10) |
| 19 | M + A | 16 | Venom Spore unlocked |
| 20 | P + A | 18 | **Pharaoh Colossus** |
| 21 | S | 14 | Regenerators; ice paths |
| 22 | F | 15 | Frost-resistant variants |
| 23 | X | 15 | Amplifier unlocked |
| 24 | L | 16 | Phantoms (stealth) |
| 25 | F + A | 16 | **Frost Wraith** |
| 26 | P | 16 | Three parallel lanes |
| 27 | M + A | 17 | Gunships |
| 28 | X | 17 | Ice paths on a crossing |
| 29 | P + A | 18 | Mixed everything, limited pads |
| 30 | F + A | 20 | **Glacier Titan** |
| 31 | S | 15 | Prism Laser unlocked; power nodes |
| 32 | F | 16 | Conveyors |
| 33 | L | 16 | Burrowers |
| 34 | M | 17 | Node fights: best pads on far side |
| 35 | X + A | 18 | **Overclock Mech** |
| 36 | P | 18 | Conveyor reverses each wave |
| 37 | F + A | 18 | Gunship swarms |
| 38 | M | 19 | Wardens |
| 39 | X + A | 19 | 12 pads only |
| 40 | P + A | 20 | **Foundry Dreadnought** |
| 41 | S | 16 | Rifts |
| 42 | F | 17 | Rift loops back to start |
| 43 | X | 18 | Phantom + Mender combos |
| 44 | M + A | 18 | All air types |
| 45 | P | 19 | **Rift Stalker** |
| 46 | L + A | 20 | Warden escorts |
| 47 | X | 20 | Four spawns |
| 48 | P + A | 20 | 10 pads, everything resistant |
| 49 | M + A | 22 | Endurance gauntlet |
| 50 | F + P + A | 25 | **The Void Sovereign** |

Each level is defined in a data file (`data/levels/level_XX.tres`) holding the tilemap, path curves, pads, waves and modifiers, so new levels never need new code.

### 6.4 Hero ability

One active ability per level with a cooldown, picked from three unlocked in Research: **Airstrike** (damage line), **Time Warp** (slows everything 50% for 5s), **Gold Rush** (+100 gold).

### 6.5 Research tree (meta progression)

Spend Crystals on small perks: +5% tower damage per type, +1 life, +50 starting gold, cheaper upgrades, extra loadout slot (7th) late on. Capped so it eases difficulty but never replaces tactics. Respec is free.

### 6.6 Difficulty modes

- **Normal**: the campaign.
- **Veteran** (unlocked per level after 3 stars): +40% HP, 1 life per leak doubled, fewer pads.
- **Endless** (after level 50): infinite scaling waves on 5 maps, leaderboard via Google Play Games.

---

## 7. Mobile and Google Play

- Landscape, 16:9 to 20:9 safe areas, tap to build, tap to upgrade radial menu, pinch zoom and drag pan.
- 60 FPS target on mid-range phones; object pooling for projectiles and enemies.
- Saves: local file + Google Play Games cloud save.
- Monetisation (decide later): free with optional rewarded ads for bonus Crystals, or one-time premium unlock. No pay-to-win.
- Android export: Godot 4 Android template, AAB, target the current required API level.

---

## 8. Open questions for you

1. Title: keep "Bastion Lanes" as a placeholder or do you have a name?
2. Monetisation: free with ads, premium, or decide later?
3. Art: will you generate the tower art with an AI image tool (prompts are in `docs/art/`), and do you want me to plan for animated sprites or static sprites with code-driven effects (recommended, much cheaper)?
