class_name Tower
extends Node2D
## A tower on a build pad. Stats come from data/towers.json; each upgrade swaps the state.

const OUTLINE := Color(0.11, 0.09, 0.14)
const NEXT_STATES := {"1": ["2"], "2": ["3"], "3": ["4a", "4b"], "4a": ["5a"], "4b": ["5b"]}
const SCALE := {"1": 0.78, "2": 0.86, "3": 0.94, "4a": 1.04, "4b": 1.04, "5a": 1.14, "5b": 1.14}
const TARGET_MODES := ["first", "last", "strong", "weak", "closest"]

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
	queue_redraw()


func stat(key: String, fallback: Variant = 0.0) -> Variant:
	if stats.has(key):
		return stats[key]
	return def.get(key, fallback)


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
	return float(stat("range"))


func hits_air() -> bool:
	return bool(stat("hits_air", false))


func cycle_target_mode() -> void:
	target_mode = TARGET_MODES[(TARGET_MODES.find(target_mode) + 1) % TARGET_MODES.size()]


func _process(delta: float) -> void:
	anim += delta
	cooldown -= delta
	recoil = maxf(recoil - delta * 4.0, 0.0)
	pulse_flash = maxf(pulse_flash - delta * 2.5, 0.0)
	if def["kind"] == "pulse":
		if cooldown <= 0.0 and _enemies_in_range().size() > 0:
			_pulse()
			cooldown = 1.0 / float(stat("rate"))
	else:
		var target := _find_target()
		if target:
			aim = lerp_angle(aim, (target.position - position).angle(), minf(1.0, delta * 14.0))
			if cooldown <= 0.0:
				game.spawn_projectile(self, target)
				recoil = 1.0
				cooldown = 1.0 / float(stat("rate"))
	queue_redraw()


func _can_hit(e: Enemy) -> bool:
	if not e.alive or (e.flying and not hits_air()):
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


func _find_target() -> Enemy:
	var best: Enemy = null
	var best_score := -INF
	for e in _enemies_in_range():
		var score := 0.0
		match target_mode:
			"first": score = e.progress_ratio()
			"last": score = -e.progress_ratio()
			"strong": score = e.hp
			"weak": score = -e.hp
			"closest": score = -position.distance_to(e.position)
		if score > best_score:
			best_score = score
			best = e
	return best


func _pulse() -> void:
	pulse_flash = 1.0
	game.spawn_ring(position, range_px(), Color(def["color"]))
	var freeze_chance := float(stat("freeze_chance", 0.0))
	for e in _enemies_in_range():
		e.apply_slow(float(stat("slow", 0.0)), float(stat("slow_duration", 1.0)))
		if freeze_chance > 0.0 and randf() < freeze_chance:
			e.apply_freeze(float(stat("freeze_duration", 1.0)), float(stat("shatter", 0.0)))
		e.take_damage(float(stat("damage")), String(def["damage_type"]))


# ---------------------------------------------------------------- drawing
# Placeholder vector art; replaced by sprites from art/ once they are ready.

func _draw() -> void:
	var s: float = SCALE[state]
	var accent := Color(def["color"])
	var lvl := level_number()
	var metal := Color(0.55, 0.42, 0.28) if lvl == 1 else Color(0.66, 0.71, 0.77) if lvl == 2 else Color(0.82, 0.86, 0.9)
	var trim := Color(0.95, 0.76, 0.2) if lvl >= 3 else metal.darkened(0.3)
	match tower_id:
		"bolt": _draw_bolt(s, accent, metal, trim)
		"cannon": _draw_cannon(s, accent, metal, trim)
		"frost": _draw_frost(s, accent, metal, trim)
	_draw_pips(lvl)


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
			draw_set_transform(Vector2.ZERO, aim + anim * 20.0)
			draw_arc(Vector2.ZERO, 9.0 * s, 0, TAU, 6, accent, 3.0)
			draw_set_transform(Vector2.ZERO, aim)
		"4b", "5b":
			_bar(Vector2(back - 6, 0), Vector2(44.0 * s + back, 0), 6.0 * s, metal.lightened(0.15))
			for i in (3 if state == "4b" else 5):
				draw_circle(Vector2(14.0 + i * 7.0, 0) * s + Vector2(back, 0), 5.0 * s, accent)
		_:
			var rails := 1 if state == "1" else 2
			for i in rails:
				var off := (i - (rails - 1) / 2.0) * 7.0 * s
				_bar(Vector2(back, off), Vector2(32.0 * s + back, off), 4.5 * s, metal.lightened(0.15))
			_bar(Vector2(8 * s, -10 * s), Vector2(8 * s, 10 * s), 3.0, metal.darkened(0.2))
	_glow(Vector2.ZERO, 7.0 * s, accent if level_number() >= 2 else accent.darkened(0.3))
	draw_set_transform(Vector2.ZERO, 0.0)
	if state == "5a" or state == "5b":
		_crown(26.0 * s, accent)


func _draw_cannon(s: float, accent: Color, metal: Color, trim: Color) -> void:
	var r := 23.0 * s
	var pts := PackedVector2Array()
	for i in 8:
		pts.append(Vector2.from_angle(TAU * i / 8.0 + PI / 8.0) * r)
	var outline_pts := PackedVector2Array()
	for p in pts:
		outline_pts.append(p * (1.0 + 3.0 / r))
	draw_colored_polygon(outline_pts, OUTLINE)
	draw_colored_polygon(pts, metal.darkened(0.35))
	if level_number() >= 3:
		draw_polyline(pts + PackedVector2Array([pts[0]]), trim, 3.0)
	draw_set_transform(Vector2.ZERO, aim)
	var back := -recoil * 6.0
	match state:
		"4a", "5a":
			var n := 3 if state == "4a" else 5
			for i in n:
				var a := (i - (n - 1) / 2.0) * 0.35
				var dir := Vector2.from_angle(a)
				_bar(dir * 4.0, dir * (24.0 * s + back), 9.0 * s, Color(0.2, 0.2, 0.24))
		"4b", "5b":
			_bar(Vector2(back, 0), Vector2(42.0 * s + back, 0), 15.0 * s, Color(0.18, 0.18, 0.22))
			draw_circle(Vector2(42.0 * s + back, 0), 9.0 * s, OUTLINE)
		_:
			_bar(Vector2(back, 0), Vector2(26.0 * s + back, 0), 14.0 * s, Color(0.2, 0.2, 0.24))
			draw_circle(Vector2(27.0 * s + back, 0), 8.5 * s, OUTLINE)
	_glow(Vector2.ZERO, 8.0 * s, accent if level_number() >= 2 else accent.darkened(0.4))
	draw_set_transform(Vector2.ZERO, 0.0)
	if state == "5a" or state == "5b":
		_crown(28.0 * s, accent)


func _draw_frost(s: float, accent: Color, metal: Color, trim: Color) -> void:
	_ring(17.0 * s, Color(0.85, 0.9, 0.95) if level_number() >= 3 else metal.darkened(0.1))
	if level_number() >= 3:
		draw_arc(Vector2.ZERO, 17.0 * s, 0, TAU, 32, trim, 3.0)
	var bob := sin(anim * 2.5) * 3.0
	var h := 22.0 * s
	var w := 11.0 * s
	if state.begins_with("4b") or state.begins_with("5b"):
		draw_set_transform(Vector2(0, -8 + bob), anim * 2.0)
		for i in 4:
			var d := Vector2.from_angle(TAU * i / 4.0)
			_bar(Vector2.ZERO, d * 26.0 * s, 4.0, Color(0.9, 0.95, 1.0))
		draw_set_transform(Vector2.ZERO, 0.0)
	var c := Vector2(0, -8 + bob)
	var crystal := PackedVector2Array([c + Vector2(0, -h), c + Vector2(w, 0), c + Vector2(0, h * 0.6), c + Vector2(-w, 0)])
	var outline_pts := PackedVector2Array()
	for p in crystal:
		outline_pts.append(c + (p - c) * 1.18)
	draw_circle(c, h * 1.1, Color(accent, 0.12 + pulse_flash * 0.25))
	draw_colored_polygon(outline_pts, OUTLINE)
	draw_colored_polygon(crystal, accent.lightened(0.1 if level_number() < 3 else 0.35))
	draw_colored_polygon(PackedVector2Array([crystal[0], crystal[1], c]), Color(1, 1, 1, 0.55))
	if state == "4a" or state == "5a":
		for i in 6:
			var a := TAU * i / 6.0 + anim * 0.5
			var p := c + Vector2.from_angle(a) * (h * 0.95)
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -6), p + Vector2(3, 0), p + Vector2(0, 6), p + Vector2(-3, 0)]), Color(0.85, 0.97, 1.0))
	if level_number() >= 3 and not state.ends_with("a"):
		for i in 3:
			var a := anim * 1.5 + TAU * i / 3.0
			draw_circle(c + Vector2.from_angle(a) * h * 0.9, 3.0, Color(0.9, 1.0, 1.0))
	if state == "5a" or state == "5b":
		_crown(24.0 * s, accent)


func _crown(r: float, accent: Color) -> void:
	draw_arc(Vector2.ZERO, r + 4.0 + sin(anim * 3.0) * 2.0, 0, TAU, 40, Color(accent, 0.6), 2.5)
	for i in 5:
		var a := -PI / 2.0 + (i - 2) * 0.3
		var p := Vector2.from_angle(a) * (r + 2.0)
		draw_circle(p, 3.0, Color(1.0, 0.85, 0.25))


func _draw_pips(lvl: int) -> void:
	for i in lvl:
		var p := Vector2((i - (lvl - 1) / 2.0) * 9.0, 30.0)
		draw_circle(p, 4.0, OUTLINE)
		draw_circle(p, 2.8, Color(1.0, 0.85, 0.25))
