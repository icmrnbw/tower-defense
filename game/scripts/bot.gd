class_name Bot
extends RefCounted
## Headless test player. Follows a scripted build order and prints the result.
## Usage: godot --headless --fixed-fps 60 --path game -- --autotest=basic

const PLANS := {
	"none": [],
	"basic": [
		["build", 2, "bolt"], ["build", 5, "bolt"], ["build", 4, "cannon"], ["upgrade", 2, "2"],
		["build", 3, "frost"], ["upgrade", 5, "2"], ["build", 6, "cannon"], ["upgrade", 2, "3"],
		["upgrade", 5, "3"], ["upgrade", 4, "2"], ["build", 1, "bolt"], ["upgrade", 2, "4a"],
		["upgrade", 4, "3"], ["upgrade", 6, "2"], ["upgrade", 5, "4b"], ["upgrade", 3, "2"],
		["upgrade", 4, "4b"], ["upgrade", 6, "3"], ["upgrade", 3, "3"], ["upgrade", 1, "2"],
		["upgrade", 2, "5a"], ["upgrade", 3, "4a"], ["upgrade", 6, "4a"], ["upgrade", 5, "5b"],
		["upgrade", 4, "5b"], ["upgrade", 1, "3"], ["upgrade", 3, "5a"], ["upgrade", 6, "5a"],
	],
}

var game: Node
var strategy := ""
var plan: Array = []
var step := 0
var timer := 0.0
var elapsed := 0.0
var last_wave := -1
var shot_dir := ""
var shot_times: Array = [20.0, 75.0, 120.0]


func _init(game_ref: Node, strategy_name: String) -> void:
	game = game_ref
	strategy = strategy_name
	plan = PLANS.get(strategy, PLANS["basic"])
	print("AUTOTEST start strategy=%s" % strategy)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			shot_dir = arg.get_slice("=", 1)


func tick(delta: float) -> void:
	elapsed += delta
	if elapsed > 1500.0:
		print("AUTOTEST TIMEOUT")
		game.get_tree().quit(2)
		return
	if game.wave_index != last_wave:
		last_wave = game.wave_index
		print("  wave %d  lives=%d gold=%d step=%d t=%.0fs" % [last_wave + 1, game.lives, game.gold, step, elapsed])
	if shot_dir != "" and shot_times.size() == 2 and elapsed >= shot_times[0] - 1.0:
		game.select_pad(2)  # open an upgrade menu so the HUD shows up in the second shot
	if shot_dir != "" and not shot_times.is_empty() and elapsed >= shot_times[0]:
		_screenshot("shot_%03d.png" % int(shot_times.pop_front()))
	timer -= delta
	if timer > 0.0:
		return
	timer = 0.25
	while step < plan.size():
		var a: Array = plan[step]
		var ok: bool = game.build(a[1], a[2]) if a[0] == "build" else game.upgrade(a[1], a[2])
		if not ok:
			break
		step += 1
	if game.wave_index < 0:
		game.call_next_wave()


func finish() -> void:
	print("AUTOTEST RESULT won=%s stars=%d lives=%d wave=%d/%d gold=%d steps=%d/%d time=%.0fs" % [
		game.won, game.stars(), game.lives, game.wave_index + 1, game.level["waves"].size(),
		game.gold, step, plan.size(), elapsed])
	game.get_tree().quit(0)


func _screenshot(file_name: String) -> void:
	var img := game.get_viewport().get_texture().get_image()
	img.save_png(shot_dir.path_join(file_name))
	print("  screenshot %s" % file_name)
	game.deselect()
