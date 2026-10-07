extends Node2D
## Runs one level: map, waves, economy, towers and win/lose.
## Run with `-- --autotest=basic` (or `none`) to let a bot play headless.

signal changed  # gold, lives, wave or selection changed; the HUD refreshes on it

const LEVEL_ID := "slice_01"
const DESIGN_SIZE := Vector2(1280, 720)
const PAD_RADIUS := 30.0
const NEXT_WAVE_DELAY := 14.0
const PATH_WIDTH := 46.0

var level: Dictionary = {}
var theme_colors: Dictionary = {}
var path_points: Array = []
var paths: Array[Curve2D] = []
var air_paths: Array[Curve2D] = []
var pads: Array[Vector2] = []
var pad_towers: Array = []
var decorations: Array = []

var gold := 0
var lives := 20
var wave_index := -1
var wave_time := 0.0
var spawn_queue: Array = []
var countdown := -1.0
var alt_counter := 0
var game_over := false
var won := false
var selected_pad := -1
var speed := 1

var world: Node2D
var tower_layer: Node2D
var enemy_layer: Node2D
var projectile_layer: Node2D
var fx_layer: Node2D
var overlay: Node2D
var hud: Hud
var bot: Bot


func _ready() -> void:
	randomize()
	level = Data.load_level(LEVEL_ID)
	theme_colors = level.get("theme", {})
	gold = int(level["start_gold"])
	lives = int(level["lives"])
	for pts in level["paths"]:
		path_points.append(_to_vectors(pts))
		paths.append(_make_curve(pts))
	for pts in level.get("air_paths", []):
		air_paths.append(_make_curve(pts))
	for p in level["pads"]:
		pads.append(Vector2(p[0], p[1]))
		pad_towers.append(null)
	_make_decorations()

	world = Node2D.new()
	add_child(world)
	world.draw.connect(_draw_map)
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
			bot = Bot.new(self, arg.get_slice("=", 1) if "=" in arg else "basic")
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

func can_call_wave() -> bool:
	return not game_over and wave_index < level["waves"].size() - 1 and spawn_queue.is_empty()


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
				"path": g.get("path", 0),
				"air": g.get("air", false),
			})
	spawn_queue.sort_custom(func(a, b): return a["t"] < b["t"])
	if wave.get("boss", false):
		hud.flash("BOSS WAVE!")
	changed.emit()


func _process(delta: float) -> void:
	if game_over:
		return
	if bot:
		bot.tick(delta)
	if wave_index >= 0:
		wave_time += delta
	while not spawn_queue.is_empty() and spawn_queue[0]["t"] <= wave_time:
		_spawn(spawn_queue.pop_front())
	if spawn_queue.is_empty() and wave_index >= 0:
		if wave_index < level["waves"].size() - 1:
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
	if entry["air"]:
		curve = air_paths[0]
	elif str(entry["path"]) == "alt":
		curve = paths[alt_counter % paths.size()]
		alt_counter += 1
	else:
		curve = paths[int(entry["path"]) % paths.size()]
	var e := Enemy.new()
	var hp_level := int(level.get("hp_level", 1))
	var hp_mult := (1.0 + 0.09 * (hp_level - 1)) * (1.0 + 0.04 * wave_index)
	e.setup(entry["enemy"], hp_mult, curve)
	e.died.connect(_on_enemy_died)
	e.leaked.connect(_on_enemy_leaked)
	enemy_layer.add_child(e)


func _on_enemy_died(e: Enemy) -> void:
	gold += e.gold
	fx_layer.add_child(Fx.make("blast", e.position, e.radius * 2.0, e.color, 0.3))
	var t := Fx.make("text", e.position + Vector2(0, -e.radius), 0, Color(1.0, 0.85, 0.2), 0.7)
	t.text = "+%d" % e.gold
	fx_layer.add_child(t)
	changed.emit()


func _on_enemy_leaked(e: Enemy) -> void:
	if bot:
		print("    leak %s hp=%d/%d path=%d" % [e.enemy_id, e.hp, e.max_hp, paths.find(e.curve)])
	lives = maxi(lives - e.lives_cost, 0)
	hud.flash("-%d lives" % e.lives_cost if e.lives_cost > 1 else "")
	changed.emit()
	if lives <= 0:
		_end(false)


func stars() -> int:
	if not won:
		return 0
	return 3 if lives >= 18 else 2 if lives >= 10 else 1


func _end(victory: bool) -> void:
	if game_over:
		return
	game_over = true
	won = victory
	deselect()
	hud.show_end(victory, stars())
	if bot:
		bot.finish()


func restart() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


func set_speed(s: int) -> void:
	speed = s
	Engine.time_scale = float(s)


# ---------------------------------------------------------------- combat helpers

func spawn_projectile(tower: Tower, target: Enemy) -> void:
	var p := Projectile.new()
	p.game = self
	p.target = target
	p.target_pos = target.position
	p.speed = float(tower.stat("projectile_speed", 500.0))
	p.damage = float(tower.stat("damage"))
	p.damage_type = String(tower.def["damage_type"])
	p.hits_air = tower.hits_air()
	p.splash = float(tower.stat("splash", 0.0))
	p.stun = float(tower.stat("stun", 0.0))
	p.pierce = int(tower.stat("pierce", 0))
	p.bomblets = int(tower.stat("bomblets", 0))
	p.bomblet_damage = float(tower.stat("bomblet_damage", 0.0))
	p.bomblet_splash = float(tower.stat("bomblet_splash", 0.0))
	p.color = Color(tower.def["color"])
	p.style = "shell" if p.splash > 0.0 else "pierce" if p.pierce > 0 else "bolt"
	var dir := (target.position - tower.position).normalized()
	p.direction = dir
	p.travel_left = tower.range_px() * 1.4
	p.position = tower.position + dir * 20.0
	projectile_layer.add_child(p)


func damage_area(pos: Vector2, radius: float, damage: float, damage_type: String, air: bool, stun: float) -> void:
	for n in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e == null or not e.alive or (e.flying and not air):
			continue
		if e.position.distance_to(pos) <= radius + e.radius:
			if stun > 0.0:
				e.apply_stun(stun)
			e.take_damage(damage, damage_type)


func spawn_blast(pos: Vector2, radius: float, c: Color) -> void:
	fx_layer.add_child(Fx.make("blast", pos, radius, c, 0.3))


func spawn_ring(pos: Vector2, radius: float, c: Color) -> void:
	fx_layer.add_child(Fx.make("ring", pos, radius, c, 0.45))


# ---------------------------------------------------------------- building

func tower_at(pad: int) -> Tower:
	return pad_towers[pad] if pad >= 0 else null


func build(pad: int, tower_id: String) -> bool:
	var cost := int(Data.towers[tower_id]["states"]["1"]["cost"])
	if game_over or pad_towers[pad] != null or gold < cost:
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
			if pads[i].distance_to(p) <= PAD_RADIUS + 8.0:
				hit = i
				break
		select_pad(hit if hit != selected_pad else -1)
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- drawing

func _make_decorations() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(level["id"])
	var tries := 0
	while decorations.size() < 34 and tries < 600:
		tries += 1
		var p := Vector2(rng.randf_range(10, 1270), rng.randf_range(70, 710))
		var ok := true
		for c in paths:
			if c.get_closest_point(p).distance_to(p) < PATH_WIDTH:
				ok = false
		for pad in pads:
			if pad.distance_to(p) < PAD_RADIUS + 26.0:
				ok = false
		for d in decorations:
			if d["pos"].distance_to(p) < 36.0:
				ok = false
		if ok:
			decorations.append({"pos": p, "kind": "tree" if rng.randf() < 0.7 else "rock", "size": rng.randf_range(0.7, 1.2)})


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
	var outline := Color(0.11, 0.09, 0.14)
	for d in decorations:
		var p: Vector2 = d["pos"]
		var s: float = d["size"]
		if d["kind"] == "tree":
			world.draw_circle(p + Vector2(4, 6), 16 * s, Color(0, 0, 0, 0.2))
			world.draw_circle(p, 17 * s, outline)
			world.draw_circle(p, 15 * s, Color(0.2, 0.5, 0.22))
			world.draw_circle(p + Vector2(-4, -5) * s, 9 * s, Color(0.3, 0.62, 0.3))
		else:
			world.draw_circle(p, 10 * s, outline)
			world.draw_circle(p, 8.5 * s, Color(0.6, 0.58, 0.55))
			world.draw_circle(p + Vector2(-2, -3) * s, 4 * s, Color(0.75, 0.73, 0.7))
	var pad_fill := Color(theme_colors.get("pad", "#b9b0a2"))
	var pad_edge := Color(theme_colors.get("pad_edge", "#4f4940"))
	for p in pads:
		world.draw_circle(p + Vector2(3, 5), PAD_RADIUS + 2, Color(0, 0, 0, 0.25))
		world.draw_circle(p, PAD_RADIUS + 3, outline)
		world.draw_circle(p, PAD_RADIUS, pad_edge)
		world.draw_circle(p + Vector2(0, -3), PAD_RADIUS - 3, pad_fill)
	# spawn and exit markers
	var start: Vector2 = path_points[0][1]
	var finish: Vector2 = path_points[0][path_points[0].size() - 2]
	world.draw_circle(Vector2(30, start.y), 18, Color(0.85, 0.2, 0.2, 0.8))
	world.draw_circle(Vector2(1250, finish.y), 18, Color(0.2, 0.45, 0.95, 0.8))


func _draw_road(pts: PackedVector2Array, width: float, c: Color) -> void:
	world.draw_polyline(pts, c, width)
	for p in pts:
		world.draw_circle(p, width * 0.5, c)


func _draw_overlay() -> void:
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
