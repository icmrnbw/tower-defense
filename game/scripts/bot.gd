class_name Bot
extends RefCounted
## Headless test player used for balancing. "auto" builds and upgrades with simple
## heuristics; "none" builds nothing (must lose).
## Usage: godot --headless --fixed-fps 60 res://scenes/main.tscn -- --level=level_07 --autotest=auto

const COMPOSITION := ["bolt", "cannon", "tesla", "inferno", "frost", "venom", "railgun", "prism"]
const AIR_CAPABLE := ["bolt", "tesla", "railgun", "skyhunter", "prism"]
const BRANCH := {"bolt": "a", "cannon": "a", "frost": "a", "tesla": "a", "railgun": "a", "inferno": "a",
		"skyhunter": "b", "venom": "b", "amplifier": "a", "prism": "b"}

var game: Node
var strategy := ""
var timer := 0.0
var elapsed := 0.0
var coverage: Array = []
var air_coverage: Array = []
var air_lanes: Array = []      # per pad: indices of air paths within reach
var built := 0
var leaks: Dictionary = {}
var needs_air := false
var needs_reveal := false
var shot_dir := ""
var shot_times: Array = []


func _init(game_ref: Node, strategy_name: String) -> void:
	game = game_ref
	strategy = strategy_name
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			shot_dir = arg.get_slice("=", 1)
			shot_times = [25.0, 140.0, 141.0]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot_times="):
			shot_times = Array(arg.get_slice("=", 1).split(",")).map(func(v): return float(v))
	for wave in game.level["waves"]:
		for g in wave["groups"]:
			var d: Dictionary = Data.enemies[g["enemy"]]
			needs_air = needs_air or d.get("flying", false)
			needs_reveal = needs_reveal or d.get("stealth", false)
	_compute_coverage()


func _compute_coverage() -> void:
	var samples: Array[Vector2] = []
	for c in game.paths:
		var length: float = c.get_baked_length()
		var d := 0.0
		while d < length:
			var p: Vector2 = c.sample_baked(d)
			if p.x > 0 and p.x < 1280 and p.y > 0 and p.y < 720:
				samples.append(p)
			d += 16.0
	var air_samples: Array[Vector2] = []
	var air_lane_of: Array[int] = []
	for li in game.air_paths.size():
		var c: Curve2D = game.air_paths[li]
		var d := 0.0
		while d < c.get_baked_length():
			air_samples.append(c.sample_baked(d))
			air_lane_of.append(li)
			d += 16.0
	for pad in game.pads:
		var lanes := {}
		for si in air_samples.size():
			if air_samples[si].distance_to(pad) <= 150.0:
				lanes[air_lane_of[si]] = true
		air_lanes.append(lanes.keys())
		var n := 0
		for s in samples:
			if s.distance_to(pad) <= 160.0:
				n += 1
		coverage.append(n)
		var a := 0
		for s in air_samples:
			if s.distance_to(pad) <= 200.0:
				a += 1
		air_coverage.append(a)


func tick(delta: float) -> void:
	elapsed += delta
	if elapsed > 3000.0:
		print("AUTOTEST TIMEOUT")
		game.get_tree().quit(2)
		return
	if shot_dir != "" and shot_times.size() == 1 and game.selected_pad < 0:
		_select_best_tower()
	if shot_dir != "" and not shot_times.is_empty() and elapsed >= shot_times[0]:
		var img: Image = game.get_viewport().get_texture().get_image()
		img.save_png(shot_dir.path_join("%s_%03d.png" % [Data.current_level, int(shot_times.pop_front())]))
	timer -= delta
	if timer > 0.0:
		return
	timer = 0.4
	if strategy == "none":
		if game.wave_index < 0:
			game.call_next_wave()
		return
	for i in 4:
		if not _act():
			break
	if game.wave_index < 0:
		game.call_next_wave()


## For the upgrade-menu screenshot: open the menu of the most upgraded tower.
func _select_best_tower() -> void:
	var best: Tower = null
	for t in game.tower_layer.get_children():
		if best == null or t.level_number() > best.level_number():
			best = t
	if best != null:
		game.select_pad(best.pad_index)


func _tower_count() -> int:
	return game.tower_layer.get_child_count()


func _act() -> bool:
	var target_towers := mini(game.pads.size(), 3 + int(game.wave_index * 0.6) + int(game.level_number / 15.0))
	var urgent := _urgent_type()
	if urgent != "":
		if game.gold < int(Data.towers[urgent]["states"]["1"]["cost"]):
			return false  # save up for it
		var upad := _best_pad(urgent)
		if upad >= 0 and game.build(upad, urgent):
			return true
	if _tower_count() < target_towers:
		var id := _next_type()
		if game.gold < int(Data.towers[id]["states"]["1"]["cost"]):
			return false
		var pad := _best_pad(id)
		if pad >= 0 and game.build(pad, id):
			built += 1
			return true
	return _upgrade()


func _upcoming(flag: String) -> bool:
	for i in [game.wave_index, game.wave_index + 1]:
		if i < 0 or i >= game.wave_count():
			continue
		for g in game.level["waves"][i]["groups"]:
			if Data.enemies[g["enemy"]].get(flag, false):
				return true
	return false


## A tower the next waves cannot be beaten without (reveal, anti-air, splash).
func _urgent_type() -> String:
	var avail: Array = game.available_towers
	var counts := {}
	var air := 0
	for t in game.tower_layer.get_children():
		counts[t.tower_id] = counts.get(t.tower_id, 0) + 1
		if t.tower_id in AIR_CAPABLE:
			air += 1
	if _tower_count() < 2:
		return ""
	if _upcoming("stealth") and "amplifier" in avail and counts.get("amplifier", 0) == 0:
		return "amplifier"
	if _upcoming("flying") and (air < 1 + game.air_paths.size() or _uncovered_air_lane() >= 0):
		return "skyhunter" if "skyhunter" in avail else "bolt"
	if _upcoming_swarm() and counts.get("cannon", 0) + counts.get("inferno", 0) == 0:
		return "cannon"
	return ""


## An air lane with no anti-air tower near it, or -1.
func _uncovered_air_lane() -> int:
	for li in game.air_paths.size():
		var covered := false
		for t in game.tower_layer.get_children():
			if t.tower_id in AIR_CAPABLE and li in air_lanes[t.pad_index]:
				covered = true
		if not covered:
			return li
	return -1


func _upcoming_swarm() -> bool:
	for i in [game.wave_index, game.wave_index + 1]:
		if i < 0 or i >= game.wave_count():
			continue
		for g in game.level["waves"][i]["groups"]:
			if int(g["count"]) >= 20:
				return true
	return false


func _next_type() -> String:
	var avail: Array = game.available_towers
	var counts := {}
	var air := 0
	for t in game.tower_layer.get_children():
		counts[t.tower_id] = counts.get(t.tower_id, 0) + 1
		if t.tower_id in AIR_CAPABLE:
			air += 1
	if _tower_count() == 0:
		return "bolt"
	if _upcoming("stealth") and "amplifier" in avail and counts.get("amplifier", 0) == 0:
		return "amplifier"
	if _upcoming("flying") and air < 2 + game.wave_index / 6:
		return "skyhunter" if "skyhunter" in avail and counts.get("skyhunter", 0) <= air / 3 else "bolt"
	var comp := COMPOSITION.filter(func(x): return x in avail)
	return comp[built % comp.size()]


func _best_pad(id: String) -> int:
	var best := -1
	var best_score := -1.0
	for i in game.pads.size():
		if game.pad_towers[i] != null:
			continue
		var score := float(coverage[i])
		if id == "skyhunter":
			score = float(air_coverage[i]) * 2.0 + coverage[i] * 0.2
		if id in AIR_CAPABLE and needs_air:
			var gap := _uncovered_air_lane()
			if gap >= 0 and gap in air_lanes[i]:
				score += 1000.0
		if id == "amplifier":
			for t in game.tower_layer.get_children():
				if t.position.distance_to(game.pads[i]) <= 150.0:
					score += 10.0
		if game.power_pads.has(i):
			score *= 1.2
		if score > best_score:
			best_score = score
			best = i
	return best


func _upgrade() -> bool:
	var air_boss_soon := false
	for i in range(maxi(game.wave_index, 0), mini(game.wave_index + 4, game.wave_count())):
		for g in game.level["waves"][i]["groups"]:
			var d: Dictionary = Data.enemies[g["enemy"]]
			air_boss_soon = air_boss_soon or (d.get("boss", false) and d.get("flying", false))
	var best: Tower = null
	var best_score := -1.0
	var best_state := ""
	for t in game.tower_layer.get_children():
		var nexts: Array = t.next_states()
		if nexts.is_empty():
			continue
		var s: String = nexts[0]
		if nexts.size() == 2:
			s = "4" + BRANCH.get(t.tower_id, "a")
		var score := float(coverage[t.pad_index] + 5) / float(t.level_number())
		if air_boss_soon and t.tower_id in AIR_CAPABLE:
			score *= 4.0
		if score > best_score:
			best_score = score
			best = t
			best_state = s
	if best == null or game.gold < best.upgrade_cost(best_state):
		return false
	return game.upgrade(best.pad_index, best_state)


func on_leak(e: Enemy) -> void:
	leaks[e.enemy_id] = leaks.get(e.enemy_id, 0) + e.lives_cost


func finish() -> void:
	var towers := {}
	for t in game.tower_layer.get_children():
		var key: String = t.tower_id + "_" + t.state
		towers[key] = towers.get(key, 0) + 1
	var result := {
		"level": Data.current_level, "won": game.won, "stars": game.stars(), "lives": game.lives,
		"wave": game.wave_index + 1, "waves": game.wave_count(), "gold": game.gold,
		"time": int(elapsed), "leaks": leaks, "towers": towers,
	}
	print("AUTOTEST RESULT " + JSON.stringify(result))
	game.get_tree().quit(0)
