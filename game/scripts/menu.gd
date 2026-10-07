extends Control
## World map: pick a world, then a level. Levels unlock by clearing the previous one.

const GOLD := Color(1.0, 0.85, 0.25)

var world_index := 0
var world_box: HBoxContainer
var level_grid: GridContainer
var world_title: Label
var info: Label
var background: ColorRect


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = _make_theme()
	background = ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 18)
	add_child(col)

	var title := Label.new()
	title.text = "BASTION LANES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", GOLD)
	title.add_theme_constant_override("outline_size", 12)
	col.add_child(title)

	info = Label.new()
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(info)

	world_box = HBoxContainer.new()
	world_box.alignment = BoxContainer.ALIGNMENT_CENTER
	world_box.add_theme_constant_override("separation", 10)
	col.add_child(world_box)

	world_title = Label.new()
	world_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	world_title.add_theme_font_size_override("font_size", 30)
	col.add_child(world_title)

	var center := CenterContainer.new()
	col.add_child(center)
	level_grid = GridContainer.new()
	level_grid.columns = 5
	level_grid.add_theme_constant_override("h_separation", 12)
	level_grid.add_theme_constant_override("v_separation", 12)
	center.add_child(level_grid)

	# open on the world of the furthest unlocked level
	for i in Data.levels.size():
		if Data.is_unlocked(i):
			world_index = int(Data.levels[i]["world"]) - 1
	_refresh()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			_screenshot(arg.get_slice("=", 1))


## Screenshot mode for docs: `-- --shots=DIR` saves the world map and quits.
func _screenshot(dir: String) -> void:
	await get_tree().create_timer(1.0).timeout
	get_viewport().get_texture().get_image().save_png(dir.path_join("menu.png"))
	get_tree().quit()


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 22
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		var b := StyleBoxFlat.new()
		b.set_corner_radius_all(12)
		b.set_content_margin_all(10)
		b.border_color = Color(0.11, 0.09, 0.14)
		b.set_border_width_all(3)
		match st:
			"normal": b.bg_color = Color(0.26, 0.24, 0.36)
			"hover": b.bg_color = Color(0.34, 0.31, 0.46)
			"pressed": b.bg_color = Color(0.45, 0.38, 0.2)
			"disabled": b.bg_color = Color(0.16, 0.15, 0.2, 0.8)
			"focus":
				b.draw_center = false
				b.border_color = Color(1, 1, 1, 0.0)
		t.set_stylebox(st, "Button", b)
	t.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.3))
	t.set_color("font_outline_color", "Label", Color(0.1, 0.08, 0.12))
	t.set_constant("outline_size", "Label", 6)
	return t


func _refresh() -> void:
	var w: Dictionary = Data.worlds[world_index]
	background.color = Color(w.get("menu_color", "#24303a"))
	info.text = "Stars: %d / %d" % [Data.total_stars(), Data.levels.size() * 3]
	for c in world_box.get_children():
		c.queue_free()
	for i in Data.worlds.size():
		var b := Button.new()
		b.text = "%d. %s" % [i + 1, Data.worlds[i]["name"]]
		b.custom_minimum_size = Vector2(190, 56)
		b.add_theme_font_size_override("font_size", 18)
		b.disabled = not Data.is_unlocked(i * 10)
		if i == world_index:
			b.add_theme_color_override("font_color", GOLD)
		b.pressed.connect(func():
			world_index = i
			_refresh())
		world_box.add_child(b)
	world_title.text = w["name"]
	world_title.add_theme_color_override("font_color", Color(w.get("accent", "#ffffff")))
	for c in level_grid.get_children():
		c.queue_free()
	for i in Data.levels.size():
		var entry: Dictionary = Data.levels[i]
		if int(entry["world"]) != world_index + 1:
			continue
		var b := Button.new()
		var s := Data.stars(entry["id"])
		var unlocked := Data.is_unlocked(i)
		var boss := int(entry["number"]) % 5 == 0
		b.text = "%d%s\n%s" % [entry["number"], "  BOSS" if boss else "", ("*".repeat(s) + "-".repeat(3 - s)) if unlocked else "locked"]
		b.custom_minimum_size = Vector2(150, 90)
		b.disabled = not unlocked
		if boss:
			b.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))
		var id: String = entry["id"]
		b.pressed.connect(func():
			Data.current_level = id
			get_tree().change_scene_to_file("res://scenes/main.tscn"))
		level_grid.add_child(b)
