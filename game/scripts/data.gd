extends Node
## Loads all game data from JSON so balancing never needs code changes.

var towers: Dictionary = {}
var enemies: Dictionary = {}


func _ready() -> void:
	towers = load_json("res://data/towers.json")
	enemies = load_json("res://data/enemies.json")


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
