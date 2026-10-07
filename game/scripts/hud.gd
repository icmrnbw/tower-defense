class_name Hud
extends CanvasLayer
## Touch-first HUD: top bar, build menu, upgrade menu, messages and the end screen.

const BG := Color(0.1, 0.09, 0.14, 0.9)
const GOLD := Color(1.0, 0.85, 0.25)

var game: Node
var root: Control
var gold_label: Label
var lives_label: Label
var wave_label: Label
var wave_button: Button
var speed_button: Button
var pause_button: Button
var build_menu: PanelContainer
var upgrade_menu: PanelContainer
var message: Label
var message_time := 0.0
var end_panel: PanelContainer

var _menu_key := ""
var _cost_buttons: Array = []  # [Button, cost]


func setup(game_ref: Node) -> void:
	game = game_ref
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = _make_theme()
	add_child(root)
	_build_top_bar()

	build_menu = _panel()
	upgrade_menu = _panel()
	message = Label.new()
	message.set_anchors_preset(Control.PRESET_CENTER_TOP)
	message.position.y = 80
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 30)
	message.add_theme_color_override("font_color", GOLD)
	message.add_theme_color_override("font_outline_color", Color(0.1, 0.08, 0.12))
	message.add_theme_constant_override("outline_size", 8)
	message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(message)
	game.changed.connect(refresh)


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 20
	var panel := StyleBoxFlat.new()
	panel.bg_color = BG
	panel.set_corner_radius_all(14)
	panel.set_content_margin_all(10)
	panel.border_color = Color(1, 1, 1, 0.12)
	panel.set_border_width_all(2)
	t.set_stylebox("panel", "PanelContainer", panel)
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		var b := StyleBoxFlat.new()
		b.set_corner_radius_all(10)
		b.set_content_margin_all(10)
		match st:
			"normal": b.bg_color = Color(0.26, 0.24, 0.36)
			"hover": b.bg_color = Color(0.34, 0.31, 0.46)
			"pressed": b.bg_color = Color(0.45, 0.38, 0.2)
			"disabled": b.bg_color = Color(0.18, 0.17, 0.22)
			"focus":
				b.draw_center = false
				b.border_color = Color(1, 1, 1, 0.0)
		t.set_stylebox(st, "Button", b)
	t.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.35))
	t.set_color("font_outline_color", "Label", Color(0.1, 0.08, 0.12))
	t.set_constant("outline_size", "Label", 4)
	return t


func _panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.visible = false
	root.add_child(p)
	return p


func _button(text: String, cb: Callable, min_w: float = 110.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, 64)
	b.pressed.connect(cb)
	return b


func _build_top_bar() -> void:
	var bar := PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(BG, 0.75)
	style.set_content_margin_all(6)
	style.content_margin_left = 16
	style.content_margin_right = 16
	bar.add_theme_stylebox_override("panel", style)
	root.add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	bar.add_child(row)
	gold_label = Label.new()
	gold_label.add_theme_color_override("font_color", GOLD)
	lives_label = Label.new()
	lives_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	wave_label = Label.new()
	for l in [gold_label, lives_label, wave_label]:
		l.add_theme_font_size_override("font_size", 24)
		l.custom_minimum_size.x = 120
		row.add_child(l)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	wave_button = _button("Start", func(): game.call_next_wave(), 240)
	wave_button.custom_minimum_size.y = 48
	speed_button = _button("x1", _on_speed, 64)
	speed_button.custom_minimum_size.y = 48
	pause_button = _button("II", _on_pause, 64)
	pause_button.custom_minimum_size.y = 48
	for b in [wave_button, speed_button, pause_button]:
		row.add_child(b)


func _on_speed() -> void:
	game.set_speed(game.speed % 3 + 1)
	speed_button.text = "x%d" % game.speed


func _on_pause() -> void:
	get_tree().paused = not get_tree().paused
	pause_button.text = ">" if get_tree().paused else "II"
	flash("Paused" if get_tree().paused else "")


func flash(text: String) -> void:
	if text == "":
		return
	message.text = text
	message.modulate.a = 1.0
	message_time = 1.8


# ---------------------------------------------------------------- per-frame

func tick() -> void:
	if message_time > 0.0:
		message_time -= get_process_delta_time() / maxf(Engine.time_scale, 0.01)
		message.modulate.a = clampf(message_time / 0.5, 0.0, 1.0)
	_update_wave_button()


func _update_wave_button() -> void:
	var waves: int = game.level["waves"].size()
	if game.wave_index < 0:
		wave_button.text = "Start battle"
		wave_button.disabled = false
	elif game.can_call_wave():
		wave_button.text = "Next wave  +%dg  (%d)" % [game.early_bonus(), ceili(game.countdown)]
		wave_button.disabled = false
	elif game.wave_index >= waves - 1:
		wave_button.text = "Final wave"
		wave_button.disabled = true
	else:
		wave_button.text = "Wave incoming..."
		wave_button.disabled = true


func refresh() -> void:
	gold_label.text = "Gold %d" % game.gold
	lives_label.text = "Lives %d" % game.lives
	wave_label.text = "Wave %d/%d" % [maxi(game.wave_index + 1, 0), game.level["waves"].size()]
	var pad: int = game.selected_pad
	var t: Tower = game.tower_at(pad)
	var key := "" if pad < 0 else "%d:%s:%s" % [pad, t.state if t else "-", t.target_mode if t else ""]
	if key != _menu_key:
		_menu_key = key
		_rebuild_menus(pad, t)
	for entry in _cost_buttons:
		entry[0].disabled = game.gold < entry[1]
	game.overlay.queue_redraw()


# ---------------------------------------------------------------- menus

func _clear(panel: PanelContainer) -> void:
	for c in panel.get_children():
		panel.remove_child(c)
		c.queue_free()


func _rebuild_menus(pad: int, t: Tower) -> void:
	_cost_buttons.clear()
	_clear(build_menu)
	_clear(upgrade_menu)
	build_menu.visible = pad >= 0 and t == null
	upgrade_menu.visible = pad >= 0 and t != null
	if pad < 0:
		return
	if t == null:
		var row := HBoxContainer.new()
		build_menu.add_child(row)
		for id in Data.towers:
			var cost := int(Data.towers[id]["states"]["1"]["cost"])
			var b := _button("%s\n%dg" % [Data.towers[id]["name"], cost], func(): game.build(pad, id), 130)
			b.custom_minimum_size.y = 76
			row.add_child(b)
			_cost_buttons.append([b, cost])
		_place(build_menu, pad)
	else:
		var col := VBoxContainer.new()
		upgrade_menu.add_child(col)
		var title := Label.new()
		title.text = "%s   (Lv %d)" % [t.stats["label"], t.level_number()]
		title.add_theme_color_override("font_color", GOLD)
		col.add_child(title)
		var info := Label.new()
		info.text = _stat_line(t)
		info.add_theme_font_size_override("font_size", 16)
		col.add_child(info)
		var row := HBoxContainer.new()
		col.add_child(row)
		var nexts := t.next_states()
		if nexts.is_empty():
			var maxed := Label.new()
			maxed.text = "MAX LEVEL"
			maxed.add_theme_color_override("font_color", GOLD)
			row.add_child(maxed)
		for s in nexts:
			var st: Dictionary = t.def["states"][s]
			var cost := int(st["cost"])
			var label: String = st.get("branch", "Upgrade")
			var b := _button("%s\n%dg" % [label, cost], func(): game.upgrade(pad, s), 130)
			b.custom_minimum_size.y = 76
			b.tooltip_text = st.get("desc", "")
			row.add_child(b)
			_cost_buttons.append([b, cost])
		var row2 := HBoxContainer.new()
		col.add_child(row2)
		row2.add_child(_button("Target: %s" % t.target_mode.capitalize(), func():
			t.cycle_target_mode()
			refresh(), 170))
		row2.add_child(_button("Sell %dg" % game.sell_value(t), func(): game.sell(pad), 110))
		if nexts.size() == 2:
			var hint := Label.new()
			hint.text = "A: %s   B: %s" % [t.def["states"][nexts[0]].get("desc", ""), t.def["states"][nexts[1]].get("desc", "")]
			hint.add_theme_font_size_override("font_size", 15)
			col.add_child(hint)
		_place(upgrade_menu, pad)


func _stat_line(t: Tower) -> String:
	var parts := ["DMG %d" % int(t.stat("damage")), "RATE %.1f/s" % float(t.stat("rate")), "RANGE %d" % int(t.range_px())]
	if t.stat("splash", 0.0) > 0.0:
		parts.append("SPLASH")
	if t.stat("slow", 0.0) > 0.0:
		parts.append("SLOW %d%%" % int(float(t.stat("slow")) * 100))
	parts.append("AIR" if t.hits_air() else "GROUND ONLY")
	return "  ".join(parts)


func _place(panel: PanelContainer, pad: int) -> void:
	panel.reset_size()
	var screen: Vector2 = game.world.get_global_transform() * game.pads[pad]
	var view := root.get_viewport_rect().size
	var scale_y: float = game.world.scale.y
	var pos := screen + Vector2(-panel.size.x * 0.5, (game.PAD_RADIUS + 14.0) * scale_y)
	if pos.y + panel.size.y > view.y - 8:
		pos.y = screen.y - (game.PAD_RADIUS + 14.0) * scale_y - panel.size.y
	pos.x = clampf(pos.x, 8, view.x - panel.size.x - 8)
	pos.y = clampf(pos.y, 64, view.y - panel.size.y - 8)
	panel.position = pos


# ---------------------------------------------------------------- end screen

func show_end(victory: bool, stars: int) -> void:
	build_menu.visible = false
	upgrade_menu.visible = false
	end_panel = PanelContainer.new()
	end_panel.set_anchors_preset(Control.PRESET_CENTER)
	root.add_child(end_panel)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14)
	end_panel.add_child(col)
	var title := Label.new()
	title.text = "VICTORY!" if victory else "DEFEAT"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", GOLD if victory else Color(1, 0.4, 0.4))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var sub := Label.new()
	sub.text = ("Stars: %d / 3   Lives left: %d" % [stars, game.lives]) if victory else "Reached wave %d of %d" % [game.wave_index + 1, game.level["waves"].size()]
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)
	col.add_child(_button("Play again", func(): game.restart(), 220))
	end_panel.reset_size()
	end_panel.position = (root.get_viewport_rect().size - end_panel.size) * 0.5
