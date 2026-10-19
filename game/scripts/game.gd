extends Node2D
## Runs one level: map, waves, economy, towers, world mechanics and win/lose.
## Command line: `-- --level=level_07` picks a level, `--autotest=auto` lets a bot play headless.

signal changed  # gold, lives, wave or selection changed; the HUD refreshes on it

const DESIGN_SIZE := Vector2(1280, 720)
const PAD_RADIUS := 30.0
const NEXT_WAVE_DELAY := 14.0
const PATH_WIDTH := 46.0
const NODE_BONUS := 1.25

var level: Dictionary = {}
var level_number := 1
var theme_colors: Dictionary = {}
var path_points: Array = []
var paths: Array[Curve2D] = []
var air_paths: Array[Curve2D] = []
var pads: Array[Vector2] = []
var power_pads: Dictionary = {}
var pad_towers: Array = []
var decorations: Array = []
var available_towers: Array = []

# world mechanics
var level_resist: Dictionary = {}
var ice_zones: Array = []
var rifts: Array = []
var sandstorm: Dictionary = {}
var sandstorm_timer := 0.0
var sandstorm_active := 0.0
var range_factor := 1.0
var pools: Array = []

var gold := 0
var lives := 20
var start_lives := 20
var wave_index := -1
var wave_time := 0.0
var spawn_queue: Array = []
var countdown := -1.0
var alt_counter := 0
var air_counter := 0
var game_over := false
var won := false
var selected_pad := -1
var speed := 1
var elapsed := 0.0

var world: Node2D
var ground_layer: Node2D
var tower_layer: Node2D
var enemy_layer: Node2D
var projectile_layer: Node2D
var fx_layer: Node2D
var overlay: Node2D
var hud: Hud
var bot: Bot


func _ready() -> void:
	randomize()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			Data.current_level = arg.get_slice("=", 1)
	level = Data.load_level(Data.current_level)
	level_number = int(level.get("number", 1))
	theme_colors = level.get("theme", {})
	gold = int(level["start_gold"])
	lives = int(level["lives"])
	start_lives = lives
	available_towers = Data.towers_for_level(level_number)
	for i in level["paths"].size():
		var pts: Array = level["paths"][i]
		path_points.append(_to_vectors(pts))
		paths.append(_make_curve(pts))
	for pts in level.get("air_paths", []):
		air_paths.append(_make_curve(pts))
	for i in level["pads"].size():
		var p: Array = level["pads"][i]
		pads.append(Vector2(p[0], p[1]))
		pad_towers.append(null)
		if p.size() > 2 and int(p[2]) == 1:
			power_pads[i] = true
	var mods: Dictionary = level.get("modifiers", {})
	level_resist = mods.get("resist", {})
	ice_zones = mods.get("ice", [])
	rifts = mods.get("rifts", [])
	sandstorm = mods.get("sandstorm", {})
	sandstorm_timer = float(sandstorm.get("interval", 0.0))
	_make_decorations()

	world = Node2D.new()
	add_child(world)
	world.draw.connect(_draw_map)
	ground_layer = _layer("Ground")
	ground_layer.draw.connect(_draw_ground_fx)
	tower_layer = _layer("Towers")
	enemy_layer = _layer("Enemies")
	projectile_layer = _layer("Projectiles")
	fx_layer = _layer("Fx")
	overlay = _layer("Overlay")
	overlay.draw.connect(_draw_overlay)

	hud = Hud.new()
	add_child(hud)
	hud.setup(self)
	get_viewport().size_changed.connect(_layout)
	_layout()

	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--autotest"):
			bot = Bot.new(self, arg.get_slice("=", 1) if "=" in arg else "auto")
	changed.emit()


func _layer(layer_name: String) -> Node2D:
	var n := Node2D.new()
	n.name = layer_name
	world.add_child(n)
	return n


func _to_vectors(pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(Vector2(p[0], p[1]))
	return out


func _make_curve(pts: Array) -> Curve2D:
	var c := Curve2D.new()
	c.bake_interval = 4.0
	for p in pts:
		c.add_point(Vector2(p[0], p[1]))
	return c


func _layout() -> void:
	var size := get_viewport_rect().size
	var s := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	world.scale = Vector2(s, s)
	world.position = (size - DESIGN_SIZE * s) * 0.5


# ---------------------------------------------------------------- waves

func wave_count() -> int:
	return level["waves"].size()


func can_call_wave() -> bool:
	return not game_over and wave_index < wave_count() - 1 and spawn_queue.is_empty()


func early_bonus() -> int:
	return int(countdown * 2.0) if countdown > 0.0 and wave_index >= 0 else 0


func call_next_wave() -> void:
	if not can_call_wave():
		return
	var bonus := early_bonus()
	if bonus > 0:
		gold += bonus
		hud.flash("+%d gold for calling early" % bonus)
	wave_index += 1
	wave_time = 0.0
	countdown = -1.0
	var wave: Dictionary = level["waves"][wave_index]
	for g in wave["groups"]:
		for i in int(g["count"]):
			spawn_queue.append({
				"t": float(g.get("delay", 0.0)) + i * float(g.get("interval", 1.0)),
				"enemy": g["enemy"],
				"path": g.get("path", "alt"),
				"air": Data.enemies[g["enemy"]].get("flying", false),
			})
	spawn_queue.sort_custom(func(a, b): return a["t"] < b["t"])
	if wave.get("boss", false):
		hud.flash("BOSS: %s" % Data.enemies[wave["groups"][0]["enemy"]]["name"])
	changed.emit()


func _process(delta: float) -> void:
	if game_over:
		return
	elapsed += delta
	if bot:
		bot.tick(delta)
	_update_world(delta)
	_update_buffs()
	if wave_index >= 0:
		wave_time += delta
	while not spawn_queue.is_empty() and spawn_queue[0]["t"] <= wave_time:
		_spawn(spawn_queue.pop_front())
	if spawn_queue.is_empty() and wave_index >= 0:
		if wave_index < wave_count() - 1:
			if countdown < 0.0:
				countdown = NEXT_WAVE_DELAY
			countdown -= delta
			if countdown <= 0.0:
				countdown = 0.0
				call_next_wave()
		elif get_tree().get_nodes_in_group("enemies").is_empty():
			_end(true)
	hud.tick()


func _spawn(entry: Dictionary) -> void:
	var curve: Curve2D
	var index := 0
	if entry["air"]:
		if air_paths.is_empty():
			air_paths.append(_make_curve([[-40, 360], [1320, 360]]))
		index = air_counter % air_paths.size()
		air_counter += 1
		curve = air_paths[index]
	elif str(entry["path"]) == "alt":
		index = alt_counter % paths.size()
		alt_counter += 1
		curve = paths[index]
	else:
		index = int(entry["path"]) % paths.size()
		curve = paths[index]
	spawn_enemy_at(entry["enemy"], curve, index, 0.0, -1.0)


func hp_mult_now() -> float:
	return float(level.get("hp_mult", 1.0)) * (1.0 + 0.04 * maxi(wave_index, 0))


func spawn_enemy_at(enemy_id: String, curve: Curve2D, index: int, progress: float, mult: float) -> Enemy:
	var e := Enemy.new()
	e.setup(self, enemy_id, mult if mult > 0.0 else hp_mult_now(), curve, index, progress)
	e.died.connect(_on_enemy_died)
	e.leaked.connect(_on_enemy_leaked)
	enemy_layer.add_child(e)
	return e


func _on_enemy_died(e: Enemy) -> void:
	var mult := 1.0
	for t in tower_layer.get_children():
		var tower := t as Tower
		if tower and tower.disabled_time <= 0.0 and tower.stat("gold_mult", 0.0) > 0.0 and tower.position.distance_to(e.position) <= tower.range_px():
			mult = maxf(mult, float(tower.stat("gold_mult")))
	var earned := int(round(e.gold * mult * float(level.get("gold_mult", 1.0))))
	gold += earned
	fx_layer.add_child(Fx.make("blast", e.position, e.radius * 2.0, e.color, 0.3))
	flash_text(e.position + Vector2(0, -e.radius), "+%d" % earned, Color(1.0, 0.85, 0.2))
	changed.emit()


func _on_enemy_leaked(e: Enemy) -> void:
	lives = maxi(lives - e.lives_cost, 0)
	if bot:
		bot.on_leak(e)
	if e.lives_cost > 1:
		hud.flash("-%d lives" % e.lives_cost)
	changed.emit()
	if lives <= 0:
		_end(false)


func stars() -> int:
	if not won:
		return 0
	var ratio := float(lives) / float(start_lives)
	return 3 if ratio >= 0.9 else 2 if ratio >= 0.5 else 1


func _end(victory: bool) -> void:
	if game_over:
		return
	game_over = true
	won = victory
	deselect()
	if victory:
		Data.record_result(Data.current_level, stars())
	hud.show_end(victory, stars())
	if bot:
		bot.finish()


func restart() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


func go_to_level(level_id: String) -> void:
	Data.current_level = level_id
	restart()


func go_to_menu() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func set_speed(s: int) -> void:
	speed = s
	Engine.time_scale = float(s)


# ---------------------------------------------------------------- world mechanics

func _update_world(delta: float) -> void:
	if not sandstorm.is_empty() and wave_index >= 0:
		if sandstorm_active > 0.0:
			sandstorm_active -= delta
			if sandstorm_active <= 0.0:
				range_factor = 1.0
				sandstorm_timer = float(sandstorm["interval"])
		else:
			sandstorm_timer -= delta
			if sandstorm_timer <= 0.0:
				sandstorm_active = float(sandstorm["duration"])
				range_factor = float(sandstorm["factor"])
				hud.flash("Sandstorm! Tower range reduced")
	for i in range(pools.size() - 1, -1, -1):
		var p: Dictionary = pools[i]
		p["time"] -= delta
		if p["time"] <= 0.0:
			pools.remove_at(i)
			continue
		var hit := {"damage": p["dps"] * delta, "type": p["type"]}
		if p["type"] == "poison":
			hit["shred"] = 0.25
		for e in enemies_near(p["pos"], p["radius"]):
			if not e.flying and e.hittable_by_area():
				apply_hit(e, hit)
	ground_layer.queue_redraw()
	overlay.queue_redraw()


func _update_buffs() -> void:
	var towers := tower_layer.get_children()
	for t in towers:
		t.reset_buffs()
		t.node_bonus = NODE_BONUS if power_pads.has(t.pad_index) else 1.0
	for a in towers:
		if a.kind() != "aura" or a.disabled_time > 0.0:
			continue
		var r: float = a.range_px()
		for t in towers:
			if t == a or t.kind() == "aura" or t.position.distance_to(a.position) > r:
				continue
			t.damage_mult = maxf(t.damage_mult, float(a.stat("damage_mult", 1.0)))
			t.rate_mult = maxf(t.rate_mult, float(a.stat("rate_mult", 1.0)))
			t.range_mult = maxf(t.range_mult, float(a.stat("range_mult", 1.0)))
			t.crit_bonus = maxf(t.crit_bonus, float(a.stat("crit_chance", 0.0)))


func ice_factor(pos: Vector2) -> float:
	for z in ice_zones:
		if pos.distance_to(Vector2(z[0], z[1])) <= float(z[2]):
			return 1.4
	return 1.0


# ---------------------------------------------------------------- queries used by enemies and towers

func enemies_near(pos: Vector2, radius: float) -> Array[Enemy]:
	var out: Array[Enemy] = []
	for n in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e and e.alive and e.position.distance_to(pos) <= radius + e.radius:
			out.append(e)
	return out


func towers_near(pos: Vector2, radius: float) -> Array[Tower]:
	var out: Array[Tower] = []
	for t in tower_layer.get_children():
		if t.position.distance_to(pos) <= radius:
			out.append(t)
	return out


func nearest_tower(pos: Vector2, radius: float) -> Tower:
	var best: Tower = null
	var best_d := radius
	for t in tower_layer.get_children():
		var d: float = t.position.distance_to(pos)
		if d <= best_d and t.disabled_time <= 0.0:
			best_d = d
			best = t
	return best


## Closest point on a ground path to pos, as [curve, path index, progress].
func ground_spot_near(pos: Vector2) -> Array:
	var best: Array = []
	var best_d := INF
	for i in paths.size():
		var off := paths[i].get_closest_offset(pos)
		var d := paths[i].sample_baked(off).distance_to(pos)
		if d < best_d:
			best_d = d
			best = [paths[i], i, off]
	return best


# ---------------------------------------------------------------- combat

func apply_hit(e: Enemy, hit: Dictionary) -> void:
	if not e.alive:
		return
	var dmg: float = hit["damage"]
	if e.is_boss and hit.get("boss_pct", 0.0) > 0.0:
		dmg += e.max_hp * float(hit["boss_pct"])
	elif not e.is_boss and hit.get("execute", 0.0) > 0.0 and e.hp_ratio() <= float(hit["execute"]):
		dmg = e.hp + e.shield + 1.0
		flash_text(e.position, "EXECUTE", Color(1.0, 0.3, 0.3))
	if hit.get("crit_chance", 0.0) > 0.0 and randf() < float(hit["crit_chance"]):
		dmg *= float(hit.get("crit_mult", 2.0))
		flash_text(e.position + Vector2(0, -10), "CRIT", Color(1.0, 0.9, 0.3))
	if hit.get("stun", 0.0) > 0.0:
		e.apply_stun(float(hit["stun"]))
	if hit.get("shred", 0.0) > 0.0:
		e.apply_shred(float(hit["shred"]), 4.0)
	if hit.get("burn_dps", 0.0) > 0.0:
		e.apply_burn(float(hit["burn_dps"]), float(hit["burn_duration"]), hit.get("spread", false))
	if hit.get("poison_dps", 0.0) > 0.0:
		e.apply_poison(float(hit["poison_dps"]), float(hit["poison_duration"]), int(hit.get("max_stacks", 5)), hit.get("spread", false))
	e.take_damage(dmg, String(hit["type"]), hit)


func damage_area(pos: Vector2, radius: float, hit: Dictionary, air: bool, ground: bool) -> void:
	for e in enemies_near(pos, radius):
		if not e.hittable_by_area() or (e.flying and not air) or (not e.flying and not ground):
			continue
		apply_hit(e, hit)


func spawn_projectile(tower: Tower, target: Enemy, volley_index: int, with_pool: bool) -> void:
	var p := Projectile.new()
	p.game = self
	p.target = target
	p.target_pos = target.position
	p.speed = float(tower.stat("projectile_speed", 500.0))
	p.hit = tower.make_hit(tower.damage())
	p.hits_air = tower.hits_air()
	p.hits_ground = tower.hits_ground()
	p.splash = float(tower.stat("splash", 0.0))
	p.pierce = int(tower.stat("pierce", 0))
	p.bomblets = int(tower.stat("bomblets", 0))
	p.bomblet_damage = float(tower.stat("bomblet_damage", 0.0)) * tower.damage_mult * tower.node_bonus
	p.bomblet_splash = float(tower.stat("bomblet_splash", 0.0))
	p.color = Color(tower.def["color"])
	p.style = "pierce" if p.pierce > 0 else String(tower.stat("style", "bolt"))
	if with_pool:
		p.pool = {"dps": float(tower.stat("pool_dps")) * tower.damage_mult * tower.node_bonus, "duration": float(tower.stat("pool_duration", 3.0)), "type": String(tower.def["damage_type"])}
	var dir := (target.position - tower.position).normalized()
	if p.style == "missile":
		dir = dir.rotated((volley_index % 2 * 2 - 1) * (0.6 + 0.15 * volley_index))
	p.direction = dir
	p.travel_left = tower.range_px() * 1.4
	p.position = tower.muzzle()
	projectile_layer.add_child(p)


func spawn_pool(pos: Vector2, radius: float, dps: float, duration: float, dtype: String) -> void:
	pools.append({"pos": pos, "radius": radius, "dps": dps, "time": duration, "max_time": duration, "type": dtype})


func spawn_blast(pos: Vector2, radius: float, c: Color) -> void:
	fx_layer.add_child(Fx.make("blast", pos, radius, c, 0.3))


func spawn_ring(pos: Vector2, radius: float, c: Color) -> void:
	fx_layer.add_child(Fx.make("ring", pos, radius, c, 0.45))


func spawn_rift_fx(pos: Vector2) -> void:
	fx_layer.add_child(Fx.make("ring", pos, 40.0, Color(0.7, 0.3, 1.0), 0.5))


func flash_text(pos: Vector2, text: String, c: Color) -> void:
	if fx_layer.get_child_count() > 120:
		return
	var t := Fx.make("text", pos, 0, c, 0.7)
	t.text = text
	fx_layer.add_child(t)


# ---------------------------------------------------------------- building

func tower_at(pad: int) -> Tower:
	return pad_towers[pad] if pad >= 0 else null


func build(pad: int, tower_id: String) -> bool:
	var cost := int(Data.towers[tower_id]["states"]["1"]["cost"])
	if game_over or pad_towers[pad] != null or gold < cost or not tower_id in available_towers:
		return false
	var t := Tower.new()
	t.setup(tower_id, self, pad, wave_index)
	t.position = pads[pad]
	tower_layer.add_child(t)
	pad_towers[pad] = t
	gold -= cost
	spawn_ring(t.position, 40.0, Color(1, 1, 1))
	changed.emit()
	return true


func upgrade(pad: int, new_state: String) -> bool:
	var t := tower_at(pad)
	if t == null or game_over or not new_state in t.next_states():
		return false
	var cost := t.upgrade_cost(new_state)
	if gold < cost:
		return false
	gold -= cost
	t.upgrade(new_state)
	spawn_ring(t.position, 50.0, Color(1.0, 0.85, 0.25))
	changed.emit()
	return true


func sell_value(t: Tower) -> int:
	return t.spent if t.built_wave == wave_index else int(t.spent * 0.7)


func sell(pad: int) -> void:
	var t := tower_at(pad)
	if t == null or game_over:
		return
	gold += sell_value(t)
	pad_towers[pad] = null
	tower_layer.remove_child(t)
	t.queue_free()
	deselect()


func select_pad(pad: int) -> void:
	selected_pad = pad
	overlay.queue_redraw()
	changed.emit()


func deselect() -> void:
	select_pad(-1)


func _unhandled_input(event: InputEvent) -> void:
	if game_over:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p := world.get_local_mouse_position()
		var hit := -1
		for i in pads.size():
			if pads[i].distance_to(p) <= PAD_RADIUS + 10.0:
				hit = i
				break
		select_pad(hit if hit != selected_pad else -1)
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- drawing

func _make_decorations() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(level["id"])
	var tries := 0
	while decorations.size() < 34 and tries < 800:
		tries += 1
		var p := Vector2(rng.randf_range(10, 1270), rng.randf_range(70, 710))
		var ok := true
		for c in paths:
			if c.get_closest_point(p).distance_to(p) < PATH_WIDTH:
				ok = false
				break
		for pad in pads:
			if pad.distance_to(p) < PAD_RADIUS + 26.0:
				ok = false
				break
		for d in decorations:
			if d["pos"].distance_to(p) < 36.0:
				ok = false
				break
		if ok:
			decorations.append({"pos": p, "big": rng.randf() < 0.7, "size": rng.randf_range(0.7, 1.2), "seed": rng.randf()})


func _draw_map() -> void:
	var grass := Color(theme_colors.get("grass", "#4a8a3f"))
	var grass_alt := Color(theme_colors.get("grass_alt", "#447f3a"))
	world.draw_rect(Rect2(-2000, -2000, 5280, 4720), grass)
	for x in 20:
		for y in 12:
			if (x + y) % 2 == 0:
				world.draw_rect(Rect2(x * 64, y * 64, 64, 64), grass_alt)
	var edge := Color(theme_colors.get("path_edge", "#9c7a45"))
	var dirt := Color(theme_colors.get("path", "#d9b77a"))
	for pts in path_points:
		_draw_road(pts, PATH_WIDTH + 10.0, edge)
	for pts in path_points:
		_draw_road(pts, PATH_WIDTH, dirt)
	for pts in path_points:
		world.draw_polyline(pts, Color(1, 1, 1, 0.12), 3.0)
	for z in ice_zones:
		world.draw_circle(Vector2(z[0], z[1]), float(z[2]), Color(0.75, 0.92, 1.0, 0.55))
		world.draw_arc(Vector2(z[0], z[1]), float(z[2]), 0, TAU, 32, Color(1, 1, 1, 0.7), 2.0)
	for d in decorations:
		_draw_decoration(d)
	var pad_fill := Color(theme_colors.get("pad", "#b9b0a2"))
	var pad_edge := Color(theme_colors.get("pad_edge", "#4f4940"))
	var outline := Color(0.11, 0.09, 0.14)
	for i in pads.size():
		var p := pads[i]
		world.draw_circle(p + Vector2(3, 5), PAD_RADIUS + 2, Color(0, 0, 0, 0.25))
		world.draw_circle(p, PAD_RADIUS + 3, outline)
		world.draw_circle(p, PAD_RADIUS, Color(0.15, 0.55, 0.6) if power_pads.has(i) else pad_edge)
		world.draw_circle(p + Vector2(0, -3), PAD_RADIUS - 3, pad_fill)
		if power_pads.has(i):
			world.draw_arc(p + Vector2(0, -3), PAD_RADIUS - 6, 0, TAU, 24, Color(0.3, 1.0, 1.0, 0.8), 2.0)
	for pts in path_points:
		world.draw_circle(_edge_marker(pts[0]), 16, Color(0.85, 0.2, 0.2, 0.8))
		world.draw_circle(_edge_marker(pts[pts.size() - 1]), 16, Color(0.2, 0.45, 0.95, 0.8))
	for r in rifts:
		for end in [[r["path"], r["at"]], [r["to_path"], r["to"]]]:
			var c := paths[int(end[0])]
			var pos := c.sample_baked(float(end[1]) * c.get_baked_length())
			world.draw_circle(pos, 24, Color(0.35, 0.1, 0.5, 0.8))
			world.draw_arc(pos, 24, 0, TAU, 32, Color(0.8, 0.5, 1.0), 3.0)


func _edge_marker(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, 22, 1258), clampf(p.y, 22, 698))


func _draw_decoration(d: Dictionary) -> void:
	var p: Vector2 = d["pos"]
	var s: float = d["size"]
	var outline := Color(0.11, 0.09, 0.14)
	var w := int(level.get("world", 1))
	world.draw_circle(p + Vector2(4, 6), 14 * s, Color(0, 0, 0, 0.18))
	if not d["big"]:
		world.draw_circle(p, 10 * s, outline)
		world.draw_circle(p, 8.5 * s, Color(theme_colors.get("rock", "#99948c")))
		world.draw_circle(p + Vector2(-2, -3) * s, 4 * s, Color(1, 1, 1, 0.25))
		return
	match w:
		2:  # cactus
			world.draw_rect(Rect2(p + Vector2(-6, -18) * s, Vector2(12, 30) * s), outline)
			world.draw_rect(Rect2(p + Vector2(-4, -16) * s, Vector2(8, 26) * s), Color(0.35, 0.6, 0.3))
			world.draw_rect(Rect2(p + Vector2(4, -8) * s, Vector2(8, 5) * s), Color(0.35, 0.6, 0.3))
		3:  # ice crystal
			var pts := PackedVector2Array([p + Vector2(0, -20) * s, p + Vector2(9, 0) * s, p + Vector2(0, 8) * s, p + Vector2(-9, 0) * s])
			world.draw_colored_polygon(pts, Color(0.8, 0.95, 1.0))
			world.draw_polyline(pts + PackedVector2Array([pts[0]]), outline, 2.0)
		4:  # crate
			world.draw_rect(Rect2(p - Vector2(13, 13) * s, Vector2(26, 26) * s), outline)
			world.draw_rect(Rect2(p - Vector2(11, 11) * s, Vector2(22, 22) * s), Color(0.35, 0.37, 0.42))
			world.draw_line(p - Vector2(11, 11) * s, p + Vector2(11, 11) * s, Color(0.9, 0.3, 0.8, 0.8), 2.0)
		5:  # void crystal
			var pts := PackedVector2Array([p + Vector2(0, -22) * s, p + Vector2(7, 0) * s, p + Vector2(0, 6) * s, p + Vector2(-7, 0) * s])
			world.draw_colored_polygon(pts, Color(0.75, 0.45, 1.0))
			world.draw_polyline(pts + PackedVector2Array([pts[0]]), outline, 2.0)
			world.draw_circle(p + Vector2(0, -8) * s, 3 * s, Color(1, 0.9, 0.5))
		_:  # tree
			world.draw_circle(p, 17 * s, outline)
			world.draw_circle(p, 15 * s, Color(0.2, 0.5, 0.22))
			world.draw_circle(p + Vector2(-4, -5) * s, 9 * s, Color(0.3, 0.62, 0.3))


func _draw_road(pts: PackedVector2Array, width: float, c: Color) -> void:
	world.draw_polyline(pts, c, width)
	for p in pts:
		world.draw_circle(p, width * 0.5, c)


func _draw_ground_fx() -> void:
	for p in pools:
		var t: float = p["time"] / p["max_time"]
		var c := Color(1.0, 0.4, 0.1) if p["type"] == "fire" else Color(0.5, 0.95, 0.2)
		ground_layer.draw_circle(p["pos"], p["radius"], Color(c, 0.45 * t + 0.1))
		ground_layer.draw_circle(p["pos"], p["radius"] * 0.6, Color(c.lightened(0.3), 0.35 * t))


func _draw_overlay() -> void:
	if sandstorm_active > 0.0:
		overlay.draw_rect(Rect2(-400, -200, 2080, 1120), Color(0.85, 0.65, 0.35, 0.22))
	if selected_pad < 0:
		return
	var p := pads[selected_pad]
	overlay.draw_arc(p, PAD_RADIUS + 6, 0, TAU, 40, Color(1, 1, 1, 0.9), 3.0)
	var t := tower_at(selected_pad)
	if t:
		overlay.draw_circle(p, t.range_px(), Color(1, 1, 1, 0.1))
		overlay.draw_arc(p, t.range_px(), 0, TAU, 64, Color(1, 1, 1, 0.6), 2.0)
		var mr := float(t.stat("min_range", 0.0))
		if mr > 0.0:
			overlay.draw_arc(p, mr, 0, TAU, 32, Color(1, 0.4, 0.3, 0.6), 2.0)
