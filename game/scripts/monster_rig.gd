class_name MonsterRig
extends RefCounted
## A rigged monster from art/monsters/<id>.png + .json (made by art/src/monsters.py).
## Parts are textured quads with a pivot and a parent; poses are procedural (sine loops),
## so one atlas per monster type and no animation files. Every part also has a white
## silhouette copy in the atlas, drawn on top for hit flashes and status tints.

static var _cache: Dictionary = {}

var id := ""
var tex: Texture2D
var style := "biped"
var height := 100.0
var fit := 3.0
var motion: Dictionary = {}
var extra: Dictionary = {}
var parts: Array = []        # draw order (by z)
var solve_order: Array = []  # parents before children
var index: Dictionary = {}   # name -> part


static func get_rig(rig_id: String) -> MonsterRig:
	if _cache.has(rig_id):
		return _cache[rig_id]
	var rig: MonsterRig = null
	var path := "res://art/monsters/%s" % rig_id
	if ResourceLoader.exists(path + ".png"):
		rig = MonsterRig.new()
		rig._load(rig_id, Data.load_json(path + ".json"), load(path + ".png"))
	_cache[rig_id] = rig
	return rig


func _load(rig_id: String, meta: Dictionary, texture: Texture2D) -> void:
	id = rig_id
	tex = texture
	style = meta.get("style", "biped")
	height = float(meta.get("height", 100.0))
	fit = float(meta.get("fit", 3.0))
	motion = meta.get("motion", {})
	extra = meta
	for p in meta["parts"]:
		var r: Array = p["rect"]
		var s: Array = p["sil"]
		var part := {
			"name": p["name"], "parent": p["parent"] if p["parent"] != null else "",
			"anim": p["anim"],
			"pivot": Vector2(p["pivot"][0], p["pivot"][1]),
			"dest": Rect2(p["origin"][0], p["origin"][1], p["size"][0], p["size"][1]),
			"src": Rect2(r[0], r[1], r[2], r[3]),
			"sil": Rect2(s[0], s[1], s[2], s[3]),
		}
		parts.append(part)
		index[part["name"]] = part
	var done := {}
	while solve_order.size() < parts.size():
		for p in parts:
			if not done.has(p["name"]) and (p["parent"] == "" or done.has(p["parent"]) or not index.has(p["parent"])):
				done[p["name"]] = true
				solve_order.append(p)


## Screen pixels per art unit for an enemy of this radius.
func unit_scale(radius: float) -> float:
	return radius * fit / height


## Local transform of every part for walk phase `ph`, time `t` and cast amount `cast`.
func pose(ph: float, t: float, cast: float) -> Dictionary:
	var out := {}
	for p in solve_order:
		var a: Dictionary = p["anim"]
		var rot := 0.0
		var off := Vector2.ZERO
		var sc := Vector2.ONE
		match String(a.get("type", "")):
			"swing":
				rot = float(a["base"]) + float(a["amp"]) * sin(float(a["freq"]) * ph + float(a["phase"]))
			"flap":
				var f := sin(t * float(motion.get("flap_speed", 12.0)) + float(a["phase"]))
				rot = float(a["base"]) + float(a["amp"]) * f
				sc.y = 1.0 - 0.18 * absf(f) * float(a.get("squash", 1.0))
			"bob":
				off.y = float(a["amp"]) * sin(float(a["freq"]) * ph + float(a["phase"]))
			"spin":
				rot = ph * float(a.get("rate", 1.0))
			"drift":
				rot = float(a.get("base", 0.0)) + float(a["amp"]) * sin(t * float(a.get("speed", 2.0)) + float(a.get("phase", 0.0)))
		if a.has("cast"):
			rot = lerpf(rot, float(a["cast"]), cast)
		var pv: Vector2 = p["pivot"]
		var local := Transform2D(rot, sc, 0.0, off + pv) * Transform2D(0.0, -pv)
		var parent_name: String = p["parent"]
		out[p["name"]] = out[parent_name] * local if out.has(parent_name) else local
	return out


## Root motion (offset in art units, rotation) for the current phase.
func root_motion(ph: float, t: float) -> Transform2D:
	var y := -absf(sin(ph)) * float(motion.get("bob", 0.0))
	y += sin(t * float(motion.get("hover_speed", 2.0))) * float(motion.get("hover", 0.0))
	var rot := sin(ph) * float(motion.get("pitch", 0.0))
	return Transform2D(rot, Vector2(0, y))


## Draws the monster. `base` maps art units (feet at origin, facing +x) to the canvas item.
func draw(ci: CanvasItem, base: Transform2D, ph: float, t: float, cast: float,
		modulate: Color = Color.WHITE, overlay: Color = Color(1, 1, 1, 0)) -> void:
	var poses := pose(ph, t, cast)
	var root := base * root_motion(ph, t)
	if style == "worm":
		_draw_worm(ci, base, poses, ph, t, modulate, overlay)
		return
	for p in parts:
		if p["name"] == "shadow":
			ci.draw_set_transform_matrix(base)
		else:
			ci.draw_set_transform_matrix(root * poses[p["name"]])
		_quad(ci, p, modulate, overlay)
	ci.draw_set_transform(Vector2.ZERO, 0.0)


func _quad(ci: CanvasItem, p: Dictionary, modulate: Color, overlay: Color) -> void:
	ci.draw_texture_rect_region(tex, p["dest"], p["src"], modulate)
	if overlay.a > 0.01 and p["name"] != "shadow":
		ci.draw_texture_rect_region(tex, p["dest"], p["sil"], Color(overlay, overlay.a * modulate.a))


## Worms: a head, a repeated body segment and a tail laid along a travelling wave.
func _draw_worm(ci: CanvasItem, base: Transform2D, poses: Dictionary, ph: float, t: float,
		modulate: Color, overlay: Color) -> void:
	var n := int(extra.get("segments", 5))
	var spacing := float(extra.get("spacing", 20.0))
	var wave := float(extra.get("wave", 6.0))
	var taper := float(extra.get("taper", 0.06))
	if index.has("shadow"):
		for i in range(n + 1, -1, -1):
			ci.draw_set_transform_matrix(base * Transform2D(0.0, Vector2.ONE * (1.0 - taper * i), 0.0, Vector2(-i * spacing, 0)))
			_quad(ci, index["shadow"], modulate, overlay)
	var seg_pos := func(i: int) -> Vector2:
		return Vector2(-i * spacing, -absf(sin(ph - i * 0.9)) * wave - sin(ph - i * 0.9) * wave * 0.3)
	if index.has("tail"):
		var tp: Vector2 = seg_pos.call(n + 1)
		ci.draw_set_transform_matrix(base * Transform2D(sin(ph - n) * 0.3, Vector2.ONE * (1.0 - taper * n), 0.0, tp))
		_quad(ci, index["tail"], modulate, overlay)
	for i in range(n, 0, -1):
		var sp: Vector2 = seg_pos.call(i)
		var prev: Vector2 = seg_pos.call(i - 1)
		var tilt := (prev.y - sp.y) / spacing * 0.6
		ci.draw_set_transform_matrix(base * Transform2D(-tilt, Vector2.ONE * (1.0 - taper * i), 0.0, sp))
		_quad(ci, index["seg"], modulate, overlay)
	var hp: Vector2 = seg_pos.call(0)
	for p in parts:
		if p["name"] in ["shadow", "seg", "tail"]:
			continue
		ci.draw_set_transform_matrix(base * Transform2D(0.0, hp) * poses[p["name"]])
		_quad(ci, p, modulate, overlay)
	ci.draw_set_transform(Vector2.ZERO, 0.0)
