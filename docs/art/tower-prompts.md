# Tower Art Prompts

70 prompts: 10 towers x 7 visual states (L1, L2, L3, then Branch A L4/L5 and Branch B L4/L5).

## How to use

1. Paste the **Style prefix** first, then the tower prompt, then the **Negative prompt** (if your tool supports one; for Midjourney append `--no` with the negative terms).
2. Generate **L1 first** for each tower and pick a favourite. For L2 onward, feed the chosen L1 image back as an image/style reference (Midjourney `--cref`/`--sref`, SDXL/Flux img2img at ~0.55 to 0.65 strength, or "edit this image" in ChatGPT/Gemini). That reference is what keeps every level recognisably the same tower.
3. Export each at 512x512 PNG with transparent background. File names: `tower_<id>_<state>.png`, for example `tower_bolt_l4a.png`.

### Style prefix (use for every prompt)

> 2D mobile tower defense game asset, single tower, top-down three-quarter view (about 35 degrees), centered on a square stone build pad, bold clean dark outlines, cel-shaded with soft gradients, vibrant saturated arcade colors, crisp readable silhouette at small size, subtle rim light, isolated on transparent background, game-ready sprite, high detail, consistent lighting from top-left,

### Negative prompt

> text, letters, watermark, logo, UI, frame, border, multiple towers, characters, people, ground scenery, landscape, background, cropped, cut off, blurry, photorealistic, 3D render look, perspective distortion, side view, isometric grid, low contrast, muddy colors

### Level progression rules (apply to every tower)

These rules are what make each level feel cooler while staying recognisable. Every tower keeps its **anchor** (core silhouette shape + signature color) at every level.

| State | Size on pad | Materials | Glow / FX | Extra flair |
|---|---|---|---|---|
| L1 | ~55% of pad | Wood, rough stone, iron rivets | None, or a faint spark | Humble, hand-built |
| L2 | ~62% | Reinforced steel plates, bolts | Small glowing core in signature color | Banners or trims |
| L3 | ~70% | Polished steel, gold trim | Bright core, light emissive lines | Ornamental crest, sturdier base ring |
| L4 (branch) | ~78% | Branch-specific exotic material | Strong emissive, small particle hints | Shape now shows the branch's specialty |
| L5 (branch) | ~85%, may overhang pad | Masterwork: runic/legendary/high-tech | Intense glow, energy aura, floating parts | "Crown" element, unmistakably maxed |

---

## 1. Bolt Turret

**Anchor:** compact rotating turret with a long crossbow-like rail barrel, round swivel base. **Signature color:** brass and electric yellow.

- **L1:** a small wooden crossbow turret on a round swivel base, iron-banded bolts loaded on the rail, brass fittings, yellow painted stripe, humble hand-built look
- **L2:** the same crossbow turret upgraded with steel armor plates over the wood, a twin rail, small glowing yellow power cell at the back, yellow pennant flag
- **L3:** the same turret now fully steel with gold trim, twin long rails with crackling yellow energy lines, ornate brass gear housing, crest on the front shield
- **L4A Gatling:** the turret transformed into a rotary multi-barrel bolt gatling, six rails spinning around a glowing yellow core, ammo drum on the side, heavy steel and gold body, hot exhaust vents
- **L5A Gatling:** legendary bolt minigun fortress, eight blazing rails spinning in a ring of golden energy, floating ammo belts of glowing bolts, armored gold-and-steel cowl with a crown-shaped vent, yellow lightning sparks, same swivel base
- **L4B Piercer:** the turret reshaped into a long single heavy rail ballista, extended barrel with yellow magnetic rings along it, sleek streamlined armor, sharpened spear-like bolt loaded
- **L5B Piercer:** legendary piercer rail cannon, extremely long barrel wrapped in floating golden magnetic rings, a glowing yellow energy spear loaded, sleek gold-and-white armor with crown fins, light trail aura, same swivel base

## 2. Cannon

**Anchor:** squat round fortress body with a single wide stubby barrel. **Signature color:** dark iron and fiery orange.

- **L1:** a stubby black iron cannon on a squat round stone and timber platform, rope-tied wheels, a stack of cannonballs, orange fuse glow
- **L2:** the same cannon on a reinforced riveted iron drum base, thicker barrel with banded rings, small orange furnace glow at the breech, orange cloth banner
- **L3:** the same cannon now a polished dark-steel mortar fortress with gold trim, wide flared muzzle with orange heat glow, ornate crest, sturdy base ring with stacked glowing shells
- **L4A Cluster Bombard:** the cannon evolved into a multi-tube bombard, a revolving cluster of five short barrels around a central muzzle, glowing orange bomblets visible, heavy riveted steel
- **L5A Cluster Bombard:** legendary cluster artillery, a rotating crown of seven glowing barrels, floating orange-hot bomblets orbiting the turret, gold-and-black armor, smoke and ember aura
- **L4B Siege Howitzer:** the cannon evolved into a long-barrel siege howitzer, thick elongated barrel angled upward, hydraulic recoil pistons, orange glowing breech, armored shell rack
- **L5B Siege Howitzer:** legendary siege howitzer, colossal barrel with orange molten energy rings, massive hydraulic frame, gold-trimmed black armor, crown-shaped muzzle brake, heat shimmer and embers

## 3. Frost Spire

**Anchor:** tall slim pointed spire with a floating crystal at the top. **Signature color:** icy cyan and white.

- **L1:** a small stone spire carved with snowflake runes, a small pale-blue crystal floating at the tip, frost on the stones
- **L2:** the same spire taller with silver bands, a larger cyan crystal floating above, light snow swirling around the crystal
- **L3:** the same spire in white marble with silver-and-gold trim, a bright faceted cyan crystal floating above with three orbiting ice shards, cold mist at the base
- **L4A Glacier Heart:** the spire transformed with a huge pulsing heart-shaped ice crystal encased in a frozen cage of ice spikes, deep cyan glow, frozen ground
- **L5A Glacier Heart:** legendary glacier heart, an enormous radiant cyan crystal heart floating inside a crown of sharp ice spires, orbiting frozen shards, frost aura, white-gold runic base
- **L4B Blizzard Engine:** the spire evolved into a rotating storm engine, cyan crystal surrounded by spinning silver vanes, swirling snow vortex around the tip
- **L5B Blizzard Engine:** legendary blizzard engine, a tall white-silver spire crowned by a massive spinning ring of crystal vanes, a full swirling blizzard vortex with ice particles, glowing cyan core

## 4. Tesla Coil

**Anchor:** vertical coil column topped by a sphere. **Signature color:** copper and electric blue-violet.

- **L1:** a small copper wire coil on a wooden post topped by a small metal sphere, tiny blue spark, simple copper ring base
- **L2:** the same coil taller with ceramic insulator discs and a steel frame, the top sphere glowing blue, small electric arcs
- **L3:** the same coil in polished copper and gold with stacked glowing insulator rings, a bright blue-violet sphere crackling with lightning, ornate base
- **L4A Storm Conductor:** the coil evolved into a triple-pronged conductor, three smaller spheres around the main sphere, lightning arcing between them, storm-cloud wisps
- **L5A Storm Conductor:** legendary storm conductor, a crown of five floating spheres orbiting a giant blue-violet core, continuous lightning web between them, small thundercloud overhead, gold-copper body
- **L4B Overload:** the coil evolved into a heavy capacitor tower, a thick armored coil with glowing blue capacitor tanks, one large overcharged sphere with warning stripes
- **L5B Overload:** legendary overload reactor, an immense blue-violet plasma sphere held in a floating copper-gold cage, massive capacitor tanks, unstable energy aura, crown of insulator spikes

## 5. Railgun

**Anchor:** very long thin barrel on a tripod-like mount with a scope. **Signature color:** gunmetal and red targeting light.

- **L1:** a long rifle-like rail barrel on a wooden tripod mount, simple brass scope, red lens glint
- **L2:** the same railgun with a steel frame, longer barrel with cooling fins, glowing red scope lens, small battery pack
- **L3:** the same railgun in polished gunmetal with gold trim, magnetic accelerator coils along the barrel glowing faint red, advanced scope, ornate armored tripod
- **L4A Deadeye:** the railgun evolved into a precision sniper platform, a large multi-lens red targeting scope projecting a red laser sight, sleek black-and-gold armor
- **L5A Deadeye:** legendary deadeye, a floating red eye-shaped targeting lens above the barrel scanning with red beams, sleek black-gold body, crown-shaped scope fins, red light aura
- **L4B Executioner:** the railgun evolved into a heavy executioner cannon, a thicker barrel with a blade-like muzzle, glowing red accelerator rings, dark armored housing
- **L5B Executioner:** legendary executioner railgun, a massive barrel ending in a scythe-shaped muzzle, red energy rings floating along it, dark crimson and gold armor, menacing crown of spikes, red mist aura

## 6. Inferno

**Anchor:** brazier-shaped body with a dragon-like nozzle. **Signature color:** blackened bronze and flame red-orange.

- **L1:** a stone brazier with a crude bronze flame nozzle, small fire burning, fuel barrel beside it
- **L2:** the same brazier with an iron furnace body, a dragon-snout shaped nozzle, brighter flames, glowing grates
- **L3:** the same furnace in polished bronze and gold, a sculpted dragon-head nozzle with glowing eyes, roaring flames, ornate fire runes
- **L4A Dragon Maw:** the furnace evolved into a fierce dragon-head flamethrower, open jaws breathing fire, bronze scales, horned crest
- **L5A Dragon Maw:** legendary dragon maw, a magnificent gold-and-crimson dragon head with spread horns and flowing fire mane, roaring blue-white core flame in its jaws, ember aura, crown of horns
- **L4B Magma Forge:** the furnace evolved into a magma forge, a cracked obsidian body with glowing lava seams, molten rock dripping from a wide nozzle
- **L5B Magma Forge:** legendary magma forge, an obsidian volcano-shaped tower with rivers of glowing lava, floating molten rocks orbiting, gold forge-rune crown, heat haze aura

## 7. Skyhunter

**Anchor:** angled box launcher pointing up on a rotating base. **Signature color:** olive-white and missile red.

- **L1:** a small wooden launcher rack holding two crude rockets angled upward, rotating base, red-tipped rockets
- **L2:** the same launcher as a steel box pod with four tubes, red-tipped missiles, small radar dish
- **L3:** the same launcher in polished white steel with gold trim, six missile tubes, rotating radar dish, red targeting lights
- **L4A Swarm Battery:** the launcher evolved into a honeycomb pod of many tiny missile tubes, mini missiles peeking out, twin radar dishes
- **L5A Swarm Battery:** legendary swarm battery, a large honeycomb launcher with dozens of glowing mini missiles, floating holographic radar ring, white-gold armor, crown antennae
- **L4B Thunderhead:** the launcher evolved into a single heavy missile silo, one large missile with red warhead on a raised launch rail, armored doors open
- **L5B Thunderhead:** legendary thunderhead, a towering launch rail holding a giant glowing missile with crackling red-gold warhead, steam vents, armored gold silo crown

## 8. Venom Spore

**Anchor:** bulbous plant pod on twisting roots. **Signature color:** sickly green and purple.

- **L1:** a small bulbous green plant pod on twisting roots in a cracked clay pot, a few green spores floating
- **L2:** the same pod larger with purple veins, thorny leaves, bubbling green mist
- **L3:** the same pod in a gold-trimmed stone planter, glowing green-purple bulb, thorned tendrils, steady spore cloud
- **L4A Plague Garden:** the pod evolved into a cluster of several glowing spore bulbs on one root mass, purple flowers, thick toxic haze
- **L5A Plague Garden:** legendary plague garden, a crown of glowing green-purple bloom bulbs, floating spores orbiting, gold-trimmed planter overgrown with thorned vines, toxic aura
- **L4B Acid Geyser:** the pod evolved into a bubbling acid geyser, an open bulb mouth spraying bright green acid, corroded metal braces
- **L5B Acid Geyser:** legendary acid geyser, a towering carnivorous bulb erupting a column of glowing green acid, dripping acid droplets floating, purple gold crown of fangs

## 9. Amplifier

**Anchor:** obelisk with a ring around it. **Signature color:** white stone and gold.

- **L1:** a short stone obelisk with a small gold ring floating around it, a faint gold glow
- **L2:** the same obelisk taller with carved glyphs, a polished gold ring, small beam of light at the top
- **L3:** the same obelisk in white marble with gold inlays, two rotating gold rings, radiant gold gem at the tip
- **L4A War Totem:** the obelisk evolved into a war totem, red war banners, crossed blades at the top, rotating gold rings with red runes
- **L5A War Totem:** legendary war totem, a white-gold monolith with flaming red banners, a floating crown of golden blades, radiant red-gold aura rings
- **L4B Treasury Beacon:** the obelisk evolved into a treasury beacon, gold coins floating around it, a glowing gold gem, coin-shaped rings
- **L5B Treasury Beacon:** legendary treasury beacon, a white-gold monolith topped with a giant floating gold gem, rings of spinning gold coins, sparkling treasure aura, crown

## 10. Prism Laser

**Anchor:** faceted prism crystal mounted on a gimbal. **Signature color:** white and rainbow refraction.

- **L1:** a small clear prism crystal on a simple brass gimbal mount, faint rainbow light
- **L2:** the same prism larger, held by a steel gimbal ring, a soft white beam emitter, rainbow glints
- **L3:** the same prism in a polished white-and-gold gimbal with lens rings, the crystal glowing with rainbow refractions
- **L4A Solar Lance:** the prism evolved into a long lance emitter, an elongated crystal with focusing lenses in a line, golden sun motifs
- **L5A Solar Lance:** legendary solar lance, a long radiant crystal lance with floating golden lens rings, sunburst crown, intense white-gold light aura with rainbow edges
- **L4B Singularity Focus:** the prism evolved into a focus core, a dark faceted crystal pulling light inward, purple-white lens rings
- **L5B Singularity Focus:** legendary singularity focus, a floating black-and-violet crystal with a tiny glowing singularity at its center, light bending around it, orbiting lens rings, white-gold crown

---

## Bonus: other assets to prompt later

Enemies, bosses, tile sets for the 5 worlds, projectiles and UI icons. I'll write those prompts in step 3 once the vertical slice locks the camera angle and sprite sizes.
