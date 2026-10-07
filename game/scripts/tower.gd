class_name Tower
extends Node2D
## A tower on a build pad. Stats come from data/towers.json; each upgrade swaps the state.

const OUTLINE := Color(0.11, 0.09, 0.14)
const NEXT_STATES := {"1": ["2"], "2": ["3"], "3": ["4a", "4b"], "4a": ["5a"], "4b": ["5b"]}
const SCALE := {"1": 0.78, "2": 0.86, "3": 0.94, "4a": 1.04, "4b": 1.04, "5a": 1.14, "5b": 1.14}
const TARGET_MODES := ["first", "last", "strong", "weak", "closest"]
const SPRITE_SCALE := 0.22
const DETECT_RADIUS := 85.0
const SPRITE_PIVOT := Vector2(256, 372)

var tower_id := ""
var def: Dictionary = {}
var state := "1"
var stats: Dictionary = {}
var game: Node
var pad_index := -1
var spent := 0
var built_wave := -1
var target_mode := "first"
var cooldown := 0.0
var aim := -PI / 2.0
var anim := 0.0
var recoil := 0.0
var pulse_flash := 0.0
var sprite: Texture2D

# set by the game every frame
var damage_mult := 1.0
var rate_mult := 1.0
var range_mult := 1.0
var crit_bonus := 0.0
var node_bonus := 1.0

var disabled_time := 0.0
var disabled_color := Color.WHITE
var fire_time := 0.0
var pool_timer := 0.0
var beam_target: Enemy
var beam_time := 0.0
var beam_end := Vector2.ZERO
var lightning: Array = []


func setup(id: String, game_ref: Node, pad: int, wave: int) -> void:
	tower_id = id
	def = Data.towers[id]
	game = game_ref
	pad_index = pad
	built_wave = wave
	_set_state("1")
	spent = int(stats["cost"])


func _set_state(s: String) -> void:
	state = s
	stats = def["states"][s]
	var path := "res://art/towers/%s/tower_%s_l%s.png" % [tower_id, tower_id, s]
	sprite = load(path) if ResourceLoader.exists(path) else null
	queue_redraw()


func stat(key: String, fallback: Variant = 0.0) -> Variant:
	if stats.has(key):
		return stats[key]
	return def.get(key, fallback)


func kind() -> String:
	return def["kind"]


func level_number() -> int:
	return int(state.substr(0, 1))


func next_states() -> Array:
	return NEXT_STATES.get(state, [])


func upgrade_cost(s: String) -> int:
	return int(def["states"][s]["cost"])


func upgrade(s: String) -> void:
	spent += upgrade_cost(s)
	_set_state(s)


func range_px() -> float:
	return float(stat("range")) * range_mult * game.range_factor


func damage() -> float:
	return float(stat("damage", 0.0)) * damage_mult * node_bonus


func rate() -> float:
	return float(stat("rate", 1.0)) * rate_mult


func hits_air() -> bool:
	return bool(stat("hits_air", false))


func hits_ground() -> bool:
	return bool(stat("hits_ground", true))


func cycle_target_mode() -> void:
	target_mode = TARGET_MODES[(TARGET_MODES.find(target_mode) + 1) % TARGET_MODES.size()]


func disable(duration: float, c: Color) -> void:
	disabled_time = maxf(disabled_time, duration)
	disabled_color = c


func reset_buffs() -> void:
	damage_mult = 1.0
	rate_mult = 1.0
	range_mult = 1.0
	crit_bonus = 0.0


## Everything a hit does, handed to game.apply_hit().
func make_hit(dmg: float) -> Dictionary:
	var crit := float(stat("crit_chance", 0.0)) + crit_bonus
	return {
		"damage": dmg,
		"type": def["damage_type"],
		"armor_pierce": float(stat("armor_pierce", 0.0)),
		"crit_chance": crit,
		"crit_mult": float(stat("crit_mult", 2.0)),
		"execute": float(stat("execute", 0.0)),
		"boss_pct": float(stat("boss_pct", 0.0)),
		"stun": float(stat("stun", 0.0)),
		"shield_break": bool(stat("shield_break", false)),
		"burn_dps": float(stat("burn_dps", 0.0)) * damage_mult * node_bonus,
		"burn_duration": float(stat("burn_duration", 0.0)),
		"poison_dps": float(stat("poison_dps", 0.0)) * damage_mult * node_bonus,
		"poison_duration": float(stat("poison_duration", 0.0)),
		"max_stacks": int(stat("max_stacks", 5)),
		"shred": float(stat("shred", 0.0)),
		"spread": bool(stat("spread", false)),
	}


# ---------------------------------------------------------------- update

func _process(delta: float) -> void:
	anim += delta
	recoil = maxf(recoil - delta * 4.0, 0.0)
	pulse_flash = maxf(pulse_flash - delta * 2.5, 0.0)
	fire_time = maxf(fire_time - delta, 0.0)
	if not lightning.is_empty():
		lightning[0] -= delta
		if lightning[0] <= 0.0:
			lightning.clear()
	queue_redraw()
	if disabled_time > 0.0:
		disabled_time -= delta
		beam_target = null
		return
	cooldown -= delta
	pool_timer -= delta
	# every tower spots stealthed enemies up close; revealers see their whole range
	for e in game.enemies_near(position, range_px() if bool(stat("reveals", false)) else DETECT_RADIUS):
		e.reveal()
	match kind():
		"aura": return
		"pulse": _process_pulse()
		"beam": _process_beam(delta)
		_:
			var target := _find_target()
			if target == null:
				return
			aim = lerp_angle(aim, (target.position - position).angle(), minf(1.0, delta * 14.0))
			if cooldown > 0.0:
				return
			cooldown = 1.0 / rate()
			match kind():
				"projectile": _fire_projectiles(target)
				"chain": _fire_chain(target)
				"cone": _fire_cone(target)


func _can_hit(e: Enemy) -> bool:
	if not e.targetable():
		return false
	if e.flying and not hits_air():
		return false
	if not e.flying and not hits_ground():
		return false
	var d := position.distance_to(e.position)
	return d <= range_px() + e.radius and d >= float(stat("min_range", 0.0))


func _enemies_in_range() -> Array[Enemy]:
	var out: Array[Enemy] = []
	for n in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e and _can_hit(e):
			out.append(e)
	return out


func _score(e: Enemy) -> float:
	match target_mode:
		"last": return -e.progress_ratio()
		"strong": return e.hp + e.shield
		"weak": return -(e.hp + e.shield)
		"closest": return -position.distance_to(e.position)
	return e.progress_ratio()


func _sorted_targets() -> Array[Enemy]:
	var list := _enemies_in_range()
	list.sort_custom(func(a, b): return _score(a) > _score(b))
	return list


func _find_target() -> Enemy:
	var best: Enemy = null
	var best_score := -INF
	for e in _enemies_in_range():
		var s := _score(e)
		if s > best_score:
			best_score = s
			best = e
	return best


func _fire_projectiles(target: Enemy) -> void:
	var volley := int(stat("volley", 1))
	var targets: Array = [target] if volley == 1 else _sorted_targets()
	var spawn_pool := float(stat("pool_dps", 0.0)) > 0.0 and pool_timer <= 0.0
	if spawn_pool:
		pool_timer = float(stat("pool_interval", 1.0))
	for i in volley:
		var t: Enemy = targets[i % targets.size()]
		game.spawn_projectile(self, t, i, spawn_pool and i == 0)
	recoil = 1.0


func _process_pulse() -> void:
	if cooldown > 0.0:
		return
	var targets := _enemies_in_range()
	if targets.is_empty():
		return
	cooldown = 1.0 / rate()
	pulse_flash = 1.0
	game.spawn_ring(position, range_px(), Color(def["color"]))
	var freeze_chance := float(stat("freeze_chance", 0.0))
	var hit := make_hit(damage())
	for e in targets:
		e.apply_slow(float(stat("slow", 0.0)), float(stat("slow_duration", 1.0)))
		if freeze_chance > 0.0 and randf() < freeze_chance:
			e.apply_freeze(float(stat("freeze_duration", 1.0)), float(stat("shatter", 0.0)))
		game.apply_hit(e, hit)


func _fire_chain(target: Enemy) -> void:
	var points := [Vector2(0, -24)]
	var hit := make_hit(damage())
	var current := target
	var hit_set := {}
	for i in int(stat("chains", 1)) + 1:
		hit_set[current.get_instance_id()] = true
		points.append(current.position - position)
		game.apply_hit(current, hit)
		hit["damage"] *= float(def.get("chain_falloff", 0.8))
		var next: Enemy = null
		var best := float(def.get("chain_range", 90.0))
		for e in game.enemies_near(current.position, best):
			if e.targetable() and not hit_set.has(e.get_instance_id()) and (hits_air() or not e.flying):
				var d: float = e.position.distance_to(current.position)
				if d < best:
					best = d
					next = e
		if next == null:
			break
		current = next
	lightning = [0.15, points]
	recoil = 1.0


func _fire_cone(target: Enemy) -> void:
	fire_time = 0.3
	var half := float(stat("cone", 0.6)) * 0.5
	var hit := make_hit(damage())
	for e in _enemies_in_range():
		var dir := e.position - position
		if absf(angle_difference(aim, dir.angle())) <= half + atan2(e.radius, maxf(dir.length(), 1.0)):
			game.apply_hit(e, hit)
	if float(stat("pool_dps", 0.0)) > 0.0 and pool_timer <= 0.0:
		pool_timer = float(stat("pool_interval", 1.5))
		game.spawn_pool(target.position, 38.0, float(stat("pool_dps")) * damage_mult * node_bonus, float(stat("pool_duration", 3.0)), "fire")


func _process_beam(delta: float) -> void:
	var target := beam_target if is_instance_valid(beam_target) and _can_hit(beam_target) else null
	if target == null:
		beam_time = 0.0
		target = _find_target()
		beam_target = target
	if target == null:
		return
	beam_time += delta
	aim = (target.position - position).angle()
	var ramp := clampf(beam_time / float(stat("ramp", 3.0)), 0.0, 1.0)
	var dps := lerpf(float(stat("dps_min")), float(stat("dps_max")), ramp * ramp) * damage_mult * node_bonus
	var hit := make_hit(dps * delta)
	hit["crit_chance"] = 0.0
	if bool(stat("line", false)):
		var dir := Vector2.from_angle(aim)
		beam_end = position + dir * range_px()
		for e in game.enemies_near(position, range_px() + 30.0):
			if not e.targetable() or (e.flying and not hits_air()):
				continue
			var rel: Vector2 = e.position - position
			var along: float = rel.dot(dir)
			if along > 0.0 and absf(rel.cross(dir)) <= e.radius + 10.0:
				game.apply_hit(e, hit)
	else:
		beam_end = target.position
		game.apply_hit(target, hit)


# ---------------------------------------------------------------- drawing

func _draw() -> void:
	var accent := Color(def["color"])
	if kind() == "beam" and beam_target and is_instance_valid(beam_target) and disabled_time <= 0.0:
		var end := beam_end - position
		var ramp := clampf(beam_time / float(stat("ramp", 3.0)), 0.0, 1.0)
		var w := 3.0 + ramp * 7.0
		var beam_col := Color(0.7, 0.4, 1.0) if state.ends_with("b") else Color(1.0, 0.95, 0.6)
		draw_line(Vector2(0, -20), end, Color(beam_col, 0.35), w * 2.2)
		draw_line(Vector2(0, -20), end, beam_col, w)
		draw_line(Vector2(0, -20), end, Color.WHITE, w * 0.35)
	if sprite:
		var size := Vector2(sprite.get_size()) * SPRITE_SCALE
		draw_texture_rect(sprite, Rect2(-SPRITE_PIVOT * SPRITE_SCALE, size), false)
		if recoil > 0.6:
			draw_circle(Vector2.from_angle(aim) * 24.0 + Vector2(0, -16), 6.0 * recoil, Color(accent, 0.8))
	else:
		_draw_vector(accent)
	if kind() == "cone" and fire_time > 0.0:
		_draw_flames(accent)
	if not lightning.is_empty():
		_draw_lightning(lightning[1], accent)
	if disabled_time > 0.0:
		draw_circle(Vector2.ZERO, 30.0, Color(disabled_color, 0.35))
		draw_arc(Vector2.ZERO, 30.0, 0.0, TAU * fmod(disabled_time, 1.0), 24, disabled_color, 3.0)
	if node_bonus > 1.0:
		draw_arc(Vector2(0, 2), 33.0, 0.0, TAU, 32, Color(0.3, 1.0, 1.0, 0.6 + 0.3 * sin(anim * 4.0)), 2.0)
	_draw_pips(level_number())


func _draw_flames(accent: Color) -> void:
	var half := float(stat("cone", 0.6)) * 0.5
	var r := range_px()
	for i in 10:
		var a := aim + randf_range(-half, half)
		var d := randf_range(20.0, r)
		var c := accent.lerp(Color(1.0, 0.9, 0.3), randf())
		draw_circle(Vector2.from_angle(a) * d, 4.0 + d * 0.06, Color(c, 0.75))


func _draw_lightning(points: Array, accent: Color) -> void:
	var jag := PackedVector2Array()
	for i in points.size() - 1:
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		jag.append(a)
		var n := (b - a).orthogonal().normalized()
		for k in range(1, 4):
			jag.append(a.lerp(b, k / 4.0) + n * randf_range(-8.0, 8.0))
	jag.append(points[-1])
	draw_polyline(jag, Color(accent, 0.5), 7.0)
	draw_polyline(jag, Color(0.9, 0.9, 1.0), 2.5)


# Placeholder vector art, used until art/ has a sprite for this tower.
func _draw_vector(accent: Color) -> void:
	var s: float = SCALE[state]
	var lvl := level_number()
	var metal := Color(0.55, 0.42, 0.28) if lvl == 1 else Color(0.66, 0.71, 0.77) if lvl == 2 else Color(0.82, 0.86, 0.9)
	var trim := Color(0.95, 0.76, 0.2) if lvl >= 3 else metal.darkened(0.3)
	match tower_id:
		"bolt": _draw_bolt(s, accent, metal, trim)
		"cannon": _draw_cannon(s, accent, metal, trim)
		"frost": _draw_frost(s, accent, metal, trim)
		_: _draw_generic(s, accent, metal, trim)
	if state == "5a" or state == "5b":
		_crown(26.0 * s, accent)


func _ring(r: float, fill: Color) -> void:
	draw_circle(Vector2.ZERO, r + 3.0, OUTLINE)
	draw_circle(Vector2.ZERO, r, fill)
	draw_circle(Vector2(-r * 0.2, -r * 0.25), r * 0.55, fill.lightened(0.18))


func _bar(from: Vector2, to: Vector2, width: float, fill: Color) -> void:
	draw_line(from, to, OUTLINE, width + 5.0)
	draw_line(from, to, fill, width)


func _glow(pos: Vector2, r: float, c: Color) -> void:
	draw_circle(pos, r * 1.8, Color(c, 0.18))
	draw_circle(pos, r + 2.0, OUTLINE)
	draw_circle(pos, r, c)
	draw_circle(pos, r * 0.45, Color(1, 1, 1, 0.85))


func _poly(pts: PackedVector2Array, fill: Color, scale_by: float = 1.0) -> void:
	if scale_by != 1.0:
		for i in pts.size():
			pts[i] *= scale_by
	var c := Vector2.ZERO
	for p in pts:
		c += p
	c /= pts.size()
	var outer := PackedVector2Array()
	for p in pts:
		outer.append(c + (p - c) * 1.15)
	draw_colored_polygon(outer, OUTLINE)
	draw_colored_polygon(pts, fill)


func _draw_bolt(s: float, accent: Color, metal: Color, trim: Color) -> void:
	_ring(20.0 * s, metal.darkened(0.15))
	if level_number() >= 3:
		draw_arc(Vector2.ZERO, 20.0 * s, 0, TAU, 32, trim, 3.0)
	draw_set_transform(Vector2.ZERO, aim)
	var back := -recoil * 4.0
	match state:
		"4a", "5a":
			var n := 3 if state == "4a" else 4
			for i in n:
				var off := (i - (n - 1) / 2.0) * 6.0 * s
				_bar(Vector2(back, off), Vector2(30.0 * s + back, off), 4.0 * s, metal.lightened(0.2))
		"4b", "5b":
			_bar(Vector2(back - 6, 0), Vector2(44.0 * s + back, 0), 6.0 * s, metal.lightened(0.15))
			for i in (3 if state == "4b" else 5):
				draw_circle(Vector2(14.0 + i * 7.0, 0) * s + Vector2(back, 0), 5.0 * s, accent)
		_:
			var rails := 1 if state == "1" else 2
			for i in rails:
				var off := (i - (rails - 1) / 2.0) * 7.0 * s
				_bar(Vector2(back, off), Vector2(32.0 * s + back, off), 4.5 * s, metal.lightened(0.15))
	_glow(Vector2.ZERO, 7.0 * s, accent if level_number() >= 2 else accent.darkened(0.3))
	draw_set_transform(Vector2.ZERO, 0.0)


func _draw_cannon(s: float, accent: Color, metal: Color, trim: Color) -> void:
	var r := 23.0 * s
	var pts := PackedVector2Array()
	for i in 8:
		pts.append(Vector2.from_angle(TAU * i / 8.0 + PI / 8.0) * r)
	_poly(pts, metal.darkened(0.35))
	if level_number() >= 3:
		draw_polyline(pts + PackedVector2Array([pts[0]]), trim, 3.0)
	draw_set_transform(Vector2.ZERO, aim)
	var back := -recoil * 6.0
	match state:
		"4a", "5a":
			var n := 3 if state == "4a" else 5
			for i in n:
				var dir := Vector2.from_angle((i - (n - 1) / 2.0) * 0.35)
				_bar(dir * 4.0, dir * (24.0 * s + back), 9.0 * s, Color(0.2, 0.2, 0.24))
		"4b", "5b":
			_bar(Vector2(back, 0), Vector2(42.0 * s + back, 0), 15.0 * s, Color(0.18, 0.18, 0.22))
		_:
			_bar(Vector2(back, 0), Vector2(26.0 * s + back, 0), 14.0 * s, Color(0.2, 0.2, 0.24))
	_glow(Vector2.ZERO, 8.0 * s, accent if level_number() >= 2 else accent.darkened(0.4))
	draw_set_transform(Vector2.ZERO, 0.0)


func _draw_frost(s: float, accent: Color, metal: Color, trim: Color) -> void:
	_ring(17.0 * s, Color(0.85, 0.9, 0.95) if level_number() >= 3 else metal.darkened(0.1))
	if level_number() >= 3:
		draw_arc(Vector2.ZERO, 17.0 * s, 0, TAU, 32, trim, 3.0)
	var c := Vector2(0, -8 + sin(anim * 2.5) * 3.0)
	if state == "4b" or state == "5b":
		draw_set_transform(c, anim * 2.0)
		for i in 4:
			_bar(Vector2.ZERO, Vector2.from_angle(TAU * i / 4.0) * 26.0 * s, 4.0, Color(0.9, 0.95, 1.0))
		draw_set_transform(Vector2.ZERO, 0.0)
	var h := 22.0 * s
	var w := 11.0 * s
	draw_circle(c, h * 1.1, Color(accent, 0.12 + pulse_flash * 0.25))
	_poly(PackedVector2Array([c + Vector2(0, -h), c + Vector2(w, 0), c + Vector2(0, h * 0.6), c + Vector2(-w, 0)]), accent.lightened(0.1 if level_number() < 3 else 0.35))
	if state == "4a" or state == "5a":
		for i in 6:
			var p := c + Vector2.from_angle(TAU * i / 6.0 + anim * 0.5) * (h * 0.95)
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -6), p + Vector2(3, 0), p + Vector2(0, 6), p + Vector2(-3, 0)]), Color(0.85, 0.97, 1.0))


func _draw_generic(s: float, accent: Color, metal: Color, trim: Color) -> void:
	var lvl := level_number()
	_ring(19.0 * s, metal.darkened(0.2))
	if lvl >= 3:
		draw_arc(Vector2.ZERO, 19.0 * s, 0, TAU, 32, trim, 3.0)
	var branch_b := state.ends_with("b")
	match tower_id:
		"tesla":
			for i in 3:
				draw_arc(Vector2(0, -4), (14.0 - i * 4.0) * s, 0, TAU, 20, Color(0.8, 0.5, 0.25), 3.0)
			var spheres := 1 if lvl < 4 else (3 if state == "4a" else 5 if state == "5a" else 1)
			for i in spheres:
				var p := Vector2(0, -10) if i == 0 else Vector2.from_angle(TAU * i / (spheres - 1) + anim) * 16.0 * s + Vector2(0, -10)
				_glow(p, (9.0 if branch_b and lvl >= 4 else 7.0) * s * (1.0 if i == 0 else 0.6), accent)
		"railgun":
			draw_set_transform(Vector2.ZERO, aim)
			var length := (40.0 if lvl < 4 else 50.0) * s
			_bar(Vector2(-8 - recoil * 6.0, 0), Vector2(length - recoil * 6.0, 0), (5.0 if not branch_b else 8.0) * s, metal.darkened(0.3))
			for i in mini(lvl, 4):
				draw_circle(Vector2(10.0 + i * 8.0, 0) * s, 4.0 * s, accent)
			_glow(Vector2(-4, 0), 6.0 * s, accent)
			draw_set_transform(Vector2.ZERO, 0.0)
		"inferno":
			_poly(PackedVector2Array([Vector2(-14, 6), Vector2(14, 6), Vector2(18, -8), Vector2(-18, -8)]), Color(0.35, 0.25, 0.2), s)
			draw_set_transform(Vector2(0, -4), aim)
			_bar(Vector2.ZERO, Vector2((22.0 if state != "4a" and state != "5a" else 30.0) * s, 0), 9.0 * s, Color(0.55, 0.35, 0.2))
			draw_set_transform(Vector2.ZERO, 0.0)
			_glow(Vector2(0, -4), 7.0 * s, Color(1.0, 0.45, 0.1) if not branch_b else Color(1.0, 0.3, 0.05))
		"skyhunter":
			draw_set_transform(Vector2.ZERO, aim)
			_poly(PackedVector2Array([Vector2(-12, -12), Vector2(16, -12), Vector2(16, 12), Vector2(-12, 12)]), Color(0.9, 0.9, 0.85), s)
			var tubes := 1 if branch_b and lvl >= 4 else mini(lvl + 1, 4)
			for i in tubes:
				var y := (i - (tubes - 1) / 2.0) * 6.0 * s
				draw_circle(Vector2(12.0 * s, y), (3.0 if tubes > 1 else 8.0) * s, accent)
			draw_set_transform(Vector2.ZERO, 0.0)
		"venom":
			var bulbs := 1 if lvl < 4 or branch_b else (3 if state == "4a" else 4)
			for i in bulbs:
				var p := Vector2(0, -6) if i == 0 else Vector2.from_angle(TAU * i / (bulbs - 1)) * 12.0 * s + Vector2(0, -4)
				var r := (13.0 if i == 0 else 7.0) * s
				draw_circle(p, r + 2.5, OUTLINE)
				draw_circle(p, r, accent.darkened(0.15))
				draw_circle(p + Vector2(-r * 0.3, -r * 0.3), r * 0.35, Color(0.7, 0.4, 0.9))
			if branch_b and lvl >= 4:
				draw_circle(Vector2(0, -8), 5.0 * s, Color(0.85, 1.0, 0.3))
		"amplifier":
			_poly(PackedVector2Array([Vector2(0, -30), Vector2(9, -4), Vector2(0, 8), Vector2(-9, -4)]), Color(0.95, 0.93, 0.85), s)
			for i in mini(lvl, 3):
				draw_set_transform(Vector2(0, -10), anim * (1.0 + i * 0.5))
				draw_arc(Vector2.ZERO, (16.0 + i * 5.0) * s, 0, TAU * 0.75, 20, Color(1.0, 0.82, 0.3) if not branch_b else Color(1.0, 0.95, 0.4), 2.5)
				draw_set_transform(Vector2.ZERO, 0.0)
			_glow(Vector2(0, -24) * s, 4.0 * s, Color(1.0, 0.3, 0.3) if state.ends_with("a") and lvl >= 4 else accent)
		"prism":
			var h := 22.0 * s
			var c := Vector2(0, -8 + sin(anim * 2.0) * 2.0)
			var col := Color(0.25, 0.1, 0.35) if branch_b and lvl >= 4 else Color(0.9, 0.95, 1.0)
			_poly(PackedVector2Array([c + Vector2(0, -h), c + Vector2(h * 0.5, 0), c + Vector2(0, h * 0.5), c + Vector2(-h * 0.5, 0)]), col)
			for i in 3:
				draw_line(c, c + Vector2.from_angle(anim + TAU * i / 3.0) * h * 0.8, Color.from_hsv(fmod(anim * 0.2 + i / 3.0, 1.0), 0.6, 1.0, 0.7), 2.0)
			if lvl >= 3:
				draw_arc(c, h * 0.9, 0, TAU, 24, trim, 2.0)


func _crown(r: float, accent: Color) -> void:
	draw_arc(Vector2.ZERO, r + 4.0 + sin(anim * 3.0) * 2.0, 0, TAU, 40, Color(accent, 0.6), 2.5)
	for i in 5:
		draw_circle(Vector2.from_angle(-PI / 2.0 + (i - 2) * 0.3) * (r + 2.0), 3.0, Color(1.0, 0.85, 0.25))


func _draw_pips(lvl: int) -> void:
	for i in lvl:
		var p := Vector2((i - (lvl - 1) / 2.0) * 9.0, 30.0)
		draw_circle(p, 4.0, OUTLINE)
		draw_circle(p, 2.8, Color(1.0, 0.85, 0.25))
