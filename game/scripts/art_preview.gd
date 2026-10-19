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
	RenderingServer.set_default_clear_color(Color(0.16, 0.2, 0.15))
	match view:
		"towers": _layout_towers()
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


func _layout_monsters() -> void:
	pass


func _process(delta: float) -> void:
	t += delta
	if shot != "" and t >= time_limit:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(shot)
		get_tree().quit()
		shot = ""
