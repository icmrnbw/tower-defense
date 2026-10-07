class_name Enemy
extends Node2D
## A creep walking (or flying) along a Curve2D. Stats come from data/enemies.json.

signal died(enemy: Enemy)
signal leaked(enemy: Enemy)

const SPEED_UNIT := 55.0  # pixels per second for speed 1.0
const OUTLINE := Color(0.11, 0.09, 0.14)

var enemy_id := ""
var def: Dictionary = {}
var max_hp := 1.0
var hp := 1.0
var armor := 0.0
var flying := false
var is_boss := false
var gold := 0
var lives_cost := 1
var radius := 12.0
var color := Color.WHITE
var speed := 50.0

var curve: Curve2D
var path_length := 1.0
var progress := 0.0
var facing := 0.0
var alive := true

var slow_amount := 0.0
var slow_time := 0.0
var freeze_time := 0.0
var shatter_bonus := 0.0
var stun_time := 0.0
var flash_time := 0.0
var anim := 0.0

var ability_timer := 0.0
var harden_time := 0.0


func setup(id: String, hp_mult: float, path_curve: Curve2D) -> void:
	enemy_id = id
	def = Data.enemies[id]
	max_hp = float(def["hp"]) * hp_mult
	hp = max_hp
	armor = float(def.get("armor", 0.0))
	flying = def.get("flying", false)
	is_boss = def.get("boss", false)
	gold = int(def["gold"])
	lives_cost = int(def.get("lives", 1))
	radius = float(def.get("radius", 12))
	color = Color(def.get("color", "#ffffff"))
	speed = float(def["speed"]) * SPEED_UNIT
	ability_timer = float(def.get("ability_interval", 0.0))
	curve = path_curve
	path_length = maxf(curve.get_baked_length(), 1.0)
	position = curve.sample_baked(0.0)
	z_index = 2 if flying else 0
	add_to_group("enemies")


func _process(delta: float) -> void:
	if not alive:
		return
	flash_time = maxf(flash_time - delta, 0.0)
	freeze_time = maxf(freeze_time - delta, 0.0)
	stun_time = maxf(stun_time - delta, 0.0)
	if slow_time > 0.0:
		slow_time -= delta
		if slow_time <= 0.0:
			slow_amount = 0.0
	_update_ability(delta)

	var v := current_speed()
	progress += v * delta
	anim += delta * (1.0 + v * 0.05)
	if progress >= path_length:
		alive = false
		leaked.emit(self)
		queue_free()
		return
	var p := curve.sample_baked(progress)
	var ahead := curve.sample_baked(minf(progress + 6.0, path_length))
	if ahead.distance_squared_to(p) > 0.01:
		facing = (ahead - p).angle()
	position = p
	queue_redraw()


func _update_ability(delta: float) -> void:
	harden_time = maxf(harden_time - delta, 0.0)
	if def.get("ability", "") != "harden":
		return
	ability_timer -= delta
	if ability_timer <= 0.0:
		ability_timer = float(def["ability_interval"])
		harden_time = float(def["ability_duration"])


func current_speed() -> float:
	if freeze_time > 0.0 or stun_time > 0.0:
		return 0.0
	return speed * (1.0 - slow_amount)


func effective_armor() -> float:
	return minf(armor + (0.35 if harden_time > 0.0 else 0.0), 0.9)


func progress_ratio() -> float:
	return progress / path_length


func apply_slow(amount: float, duration: float) -> void:
	if is_boss:
		duration *= 0.5
	slow_amount = maxf(slow_amount, amount) if slow_time > 0.0 else amount
	slow_time = maxf(slow_time, duration)


func apply_freeze(duration: float, shatter: float) -> void:
	if is_boss:
		return
	freeze_time = maxf(freeze_time, duration)
	shatter_bonus = shatter


func apply_stun(duration: float) -> void:
	if is_boss:
		duration *= 0.5
	stun_time = maxf(stun_time, duration)


func take_damage(amount: float, damage_type: String) -> void:
	if not alive:
		return
	var dmg := amount
	if damage_type == "physical":
		dmg *= 1.0 - effective_armor()
	if freeze_time > 0.0:
		dmg *= 1.0 + shatter_bonus
	hp -= dmg
	flash_time = 0.06
	if hp <= 0.0:
		alive = false
		died.emit(self)
		queue_free()


func _draw() -> void:
	var body := color
	if flash_time > 0.0:
		body = Color.WHITE
	elif freeze_time > 0.0:
		body = body.lerp(Color(0.75, 0.95, 1.0), 0.75)
	elif slow_amount > 0.0:
		body = body.lerp(Color(0.45, 0.8, 1.0), 0.4)

	var lift := Vector2.ZERO
	if flying:
		draw_circle(Vector2(4, radius + 6), radius * 0.8, Color(0, 0, 0, 0.25))
		lift = Vector2(0, -6 + sin(anim * 4.0) * 2.0)
	else:
		draw_circle(Vector2(2, 4), radius, Color(0, 0, 0, 0.2))

	draw_set_transform(lift, facing)
	if flying:
		var w := radius * 1.6
		var flap := 0.6 + 0.4 * absf(sin(anim * 12.0))
		draw_colored_polygon(PackedVector2Array([Vector2(-2, 0), Vector2(-radius * 0.6, -w * flap), Vector2(radius * 0.4, -2)]), OUTLINE)
		draw_colored_polygon(PackedVector2Array([Vector2(-2, 0), Vector2(-radius * 0.6, w * flap), Vector2(radius * 0.4, 2)]), OUTLINE)
		draw_colored_polygon(PackedVector2Array([Vector2(-2, -1), Vector2(-radius * 0.5, -w * flap + 3), Vector2(radius * 0.3, -3)]), body.lightened(0.3))
		draw_colored_polygon(PackedVector2Array([Vector2(-2, 1), Vector2(-radius * 0.5, w * flap - 3), Vector2(radius * 0.3, 3)]), body.lightened(0.3))
	else:
		var step := sin(anim * 10.0) * radius * 0.25
		for side in [-1.0, 1.0]:
			draw_circle(Vector2(step * side, side * radius * 0.85), radius * 0.3, OUTLINE)
			draw_circle(Vector2(-step * side - radius * 0.4, side * radius * 0.8), radius * 0.28, OUTLINE)
	if is_boss:
		for i in 8:
			var a := TAU * i / 8.0
			var tip := Vector2.from_angle(a) * (radius + 9)
			var l := Vector2.from_angle(a - 0.25) * (radius - 2)
			var r := Vector2.from_angle(a + 0.25) * (radius - 2)
			draw_colored_polygon(PackedVector2Array([l, tip, r]), OUTLINE)
	draw_circle(Vector2.ZERO, radius + 2.5, OUTLINE)
	draw_circle(Vector2.ZERO, radius, body)
	draw_circle(Vector2(-radius * 0.25, -radius * 0.25), radius * 0.45, body.lightened(0.25))
	if armor > 0.0:
		draw_arc(Vector2.ZERO, radius - 3.0, 0.0, TAU, 24, Color(0.8, 0.83, 0.9), 3.0)
	if harden_time > 0.0:
		draw_arc(Vector2.ZERO, radius + 6.0, 0.0, TAU, 32, Color(1.0, 0.85, 0.2), 4.0)
	var eye := radius * 0.22
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(radius * 0.45, side * radius * 0.35), eye, Color.WHITE)
		draw_circle(Vector2(radius * 0.55, side * radius * 0.35), eye * 0.5, OUTLINE)
	draw_set_transform(Vector2.ZERO, 0.0)

	if hp < max_hp:
		var w2 := radius * 2.0 + 8.0
		var top := Vector2(-w2 * 0.5, -radius - 14.0 + lift.y)
		draw_rect(Rect2(top - Vector2(1, 1), Vector2(w2 + 2, 6)), OUTLINE)
		var c := Color(0.35, 0.9, 0.3) if hp / max_hp > 0.5 else Color(1.0, 0.75, 0.2) if hp / max_hp > 0.25 else Color(1.0, 0.3, 0.25)
		draw_rect(Rect2(top, Vector2(w2 * clampf(hp / max_hp, 0.0, 1.0), 4)), c)
