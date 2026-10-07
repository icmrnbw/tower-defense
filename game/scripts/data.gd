extends Node
## Loads all game data from JSON so balancing never needs code changes, and keeps player progress.

const SAVE_PATH := "user://save.json"

var towers: Dictionary = {}
var enemies: Dictionary = {}
var levels: Array = []          # index entries: {id, name, number, world}
var worlds: Array = []          # {name, ...theme}
var progress: Dictionary = {}   # level id -> best stars
var current_level := "level_01"


func _ready() -> void:
	towers = load_json("res://data/towers.json")
	enemies = load_json("res://data/enemies.json")
	var index := load_json("res://data/levels/index.json")
	levels = index.get("levels", [])
	worlds = index.get("worlds", [])
	_load_progress()


func load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid JSON in %s" % path)
		return {}
	return parsed


func load_level(level_id: String) -> Dictionary:
	return load_json("res://data/levels/%s.json" % level_id)


func level_index(level_id: String) -> int:
	for i in levels.size():
		if levels[i]["id"] == level_id:
			return i
	return -1


func next_level_id(level_id: String) -> String:
	var i := level_index(level_id)
	return levels[i + 1]["id"] if i >= 0 and i + 1 < levels.size() else ""


func is_unlocked(i: int) -> bool:
	return i == 0 or int(progress.get(levels[i - 1]["id"], 0)) > 0


func stars(level_id: String) -> int:
	return int(progress.get(level_id, 0))


func total_stars() -> int:
	var total := 0
	for k in progress:
		total += int(progress[k])
	return total


func towers_for_level(number: int) -> Array:
	var out := []
	for id in towers:
		if int(towers[id].get("unlock", 1)) <= number:
			out.append(id)
	return out


func record_result(level_id: String, earned: int) -> void:
	if earned > stars(level_id):
		progress[level_id] = earned
		_save_progress()


func _load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file else null
	if typeof(parsed) == TYPE_DICTIONARY:
		progress = parsed.get("stars", {})


func _save_progress() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"stars": progress}))
