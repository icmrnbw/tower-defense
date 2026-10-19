extends Node2D
## Art review scene. Lays out towers or monsters, animates them and can save a screenshot.
## godot --rendering-driver opengl3 res://scenes/art_preview.tscn -- --view=towers --shot=out.png [--time=1.5]

const TOWER_STATES := ["1", "2", "3", "4a", "5a", "4b", "5b"]
const SHOT_AGES := [0.0, 0.03, 0.07, 0.16, 0.25, 0.6]

var view := "towers"
var shot := ""
var time_limit := 1.2
var t := 0.0
var range_factor := 1.0
var items: Array = []


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--view="):
			view = arg.substr(7)
		elif arg.begins_with("--shot="):
			shot = arg.substr(7)
		elif arg.begins_with("--zoom="):
			scale = Vector2.ONE * float(arg.substr(7))
		elif arg.begins_with("--time="):
			time_limit = float(arg.substr(7))
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	RenderingServer.set_default_clear_color(Color(0.27, 0.48, 0.24) if view == "duel" else Color(0.16, 0.2, 0.15))
	match view:
		"towers": _layout_towers()
		"duel": _layout_duel()
		_: _layout_monsters()


func _layout_towers() -> void:
	for r in 3:
		for c in SHOT_AGES.size():
			var tw := Tower.new()
			tw.setup("bolt", self, 0, 0)
			if r > 0:
				tw._set_state(TOWER_STATES[r])
			tw.position = Vector2(110 + c * 200, 130 + r * 220)
			tw.aim = -PI / 2.0 + c * 0.7
			tw.shot_age = SHOT_AGES[c]
			add_child(tw)
			tw.set_process(false)
			items.append(tw)
	for c in 4:
		var tw := Tower.new()
		tw.setup("bolt", self, 0, 0)
		tw._set_state(TOWER_STATES[3 + c])
		tw.position = Vector2(1300 + (c % 2) * 220, 180 + (c / 2) * 300)
		tw.aim = -PI / 2.0 + c * 0.9
		tw.recoil = 0.0 if c % 2 == 0 else 0.8
		add_child(tw)
		tw.set_process(false)


var frames := 0
var frame_dir := ""
var frame_i := 0
var duel_towers: Array = []
var walkers: Array = []
var bolts: Array = []


## Crossbows tracking monsters that walk a loop around them (for GIFs: --frames=N --frame_dir=DIR).
func _layout_duel() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--frames="):
			frames = int(arg.substr(9))
		elif arg.begins_with("--frame_dir="):
			frame_dir = arg.substr(12)
	for i in 3:
		var tw := Tower.new()
		tw.setup("bolt", self, 0, 0)
		tw._set_state(TOWER_STATES[i])
		tw.position = Vector2(150 + i * 170, 190)
		add_child(tw)
		tw.set_process(false)
		duel_towers.append(tw)
	var kinds := [["goblin", 11.0], ["orc", 15.0], ["warg", 9.0], ["troll", 13.0], ["hobgoblin", 13.0], ["shaman", 12.0]]
	for i in kinds.size():
		var v := MonsterView.new()
		v.rig = MonsterRig.get_rig(kinds[i][0])
		v.radius = kinds[i][1]
		v.mode = "walk"
		v.u = float(i) / kinds.size()
		add_child(v)
		walkers.append(v)


func _process_duel(delta: float) -> void:
	for v in walkers:
		v.u = fmod(v.u + delta * 0.07, 1.0)
		var a: float = v.u * TAU
		var p := Vector2(320 + cos(a) * 290, 190 + sin(a) * 150)
		v.flip = -1.0 if sin(a) > 0.0 else 1.0
		v.position = p
	for tw in duel_towers:
		var best: Node2D = null
		for v in walkers:
			if best == null or tw.position.distance_to(v.position) < tw.position.distance_to(best.position):
				best = v
		var target: Vector2 = best.position + Vector2(0, -best.radius)
		tw.aim = lerp_angle(tw.aim, (target - tw.position).angle(), minf(1.0, delta * 14.0))
		tw.shot_age += delta
		tw.recoil = maxf(tw.recoil - delta * 4.0, 0.0)
		if tw.shot_age >= 1.0 / tw.rate():
			tw.shot_age = 0.0
			tw.recoil = 1.0
			bolts.append([tw.muzzle(), target, 0.0])
		tw.queue_redraw()
	for b in bolts:
		b[2] += delta * 3.5
	bolts = bolts.filter(func(b): return b[2] < 1.0)
	queue_redraw()


func _draw() -> void:
	for b in bolts:
		var p: Vector2 = b[0].lerp(b[1], b[2])
		var d: Vector2 = (b[1] - b[0]).normalized()
		draw_line(p - d * 12.0, p + d * 6.0, Color(0.11, 0.09, 0.14), 3.5)
		draw_line(p - d * 11.0, p + d * 5.0, Color(1.0, 0.85, 0.3), 1.8)


func _layout_monsters() -> void:
	var seen := {}
	var only := []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = arg.substr(7).split(",")
	var cols := 6
	var n := 0
	for eid in Data.enemies:
		var d: Dictionary = Data.enemies[eid]
		var art := String(d.get("art", eid))
		if seen.has(art) or (not only.is_empty() and not art in only):
			continue
		seen[art] = true
		var rig := MonsterRig.get_rig(art)
		if rig == null:
			continue
		var v := MonsterView.new()
		v.rig = rig
		v.radius = float(d["radius"])
		v.label = "%s (%s)" % [d["name"], art]
		v.flying = d.get("flying", false)
		v.position = Vector2(110 + (n % cols) * 210, 150 + (n / cols) * 190)
		v.mode = view
		add_child(v)
		n += 1


class MonsterView extends Node2D:
	var rig: MonsterRig
	var radius := 12.0
	var label := ""
	var flying := false
	var mode := "enemies"
	var ph := 0.0
	var t := 0.0
	var u := 0.0
	var flip := 1.0

	func _process(delta: float) -> void:
		t += delta
		ph += delta * 5.0
		queue_redraw()

	func _draw() -> void:
		var sc := rig.unit_scale(radius)
		var feet := Vector2(0, radius * (1.6 if flying else 0.85))
		var cols := [Color(1, 1, 1, 0), Color(1, 1, 1, 0.85), Color(0.65, 0.92, 1.0, 0.65), Color(0.5, 1.0, 0.2, 0.35)]
		if mode == "walk":
			rig.draw(self, Transform2D(0.0, Vector2(sc * flip, sc), 0.0, feet), ph, t, 0.0)
			return
		draw_line(Vector2(-90, 0), Vector2(90, 0), Color(1, 1, 1, 0.15), 1.0)
		if mode == "states":
			for i in 4:
				rig.draw(self, Transform2D(0.0, Vector2(sc, sc), 0.0, feet + Vector2(-60 + i * 45, 0)), ph, t, 1.0 if i == 3 else 0.0, Color.WHITE, cols[i])
		else:
			rig.draw(self, Transform2D(0.0, Vector2(sc, sc), 0.0, feet), ph, t, 0.0)
		draw_circle(Vector2.ZERO, 2.0, Color.RED)
		draw_string(ThemeDB.fallback_font, Vector2(-95, 45), label, HORIZONTAL_ALIGNMENT_CENTER, 190, 13)


func _process(delta: float) -> void:
	t += delta
	if view == "duel":
		_process_duel(delta)
	if frames > 0 and t > 0.3:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/f%04d.png" % [frame_dir, frame_i])
		frame_i += 1
		if frame_i >= frames:
			get_tree().quit()
		return
	if shot != "" and t >= time_limit:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(shot)
		get_tree().quit()
		shot = ""
