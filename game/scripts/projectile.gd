class_name Projectile
extends Node2D
## A shot fired by a tower. Homing shots follow their target; piercing shots fly straight.

var game: Node
var target: Enemy
var target_pos := Vector2.ZERO
var speed := 500.0
var damage := 10.0
var damage_type := "physical"
var hits_air := true
var splash := 0.0
var stun := 0.0
var pierce := 0
var bomblets := 0
var bomblet_damage := 0.0
var bomblet_splash := 0.0
var color := Color.YELLOW
var style := "bolt"
var direction := Vector2.RIGHT
var travel_left := 0.0
var _hit: Dictionary = {}


func _process(delta: float) -> void:
	if pierce > 0:
		_process_pierce(delta)
		return
	if is_instance_valid(target) and target.alive:
		target_pos = target.position
	var to := target_pos - position
	var step := speed * delta
	if to.length() <= step:
		position = target_pos
		_impact()
		return
	direction = to.normalized()
	position += direction * step
	rotation = direction.angle()
	queue_redraw()


func _process_pierce(delta: float) -> void:
	var step := speed * delta
	position += direction * step
	rotation = direction.angle()
	travel_left -= step
	for n in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e == null or not e.alive or _hit.has(e.get_instance_id()):
			continue
		if e.flying and not hits_air:
			continue
		if position.distance_to(e.position) <= e.radius + 8.0:
			_hit[e.get_instance_id()] = true
			e.take_damage(damage, damage_type)
			pierce -= 1
			if pierce <= 0:
				queue_free()
				return
	if travel_left <= 0.0:
		queue_free()


func _impact() -> void:
	if splash > 0.0:
		game.damage_area(target_pos, splash, damage, damage_type, hits_air, stun)
		game.spawn_blast(target_pos, splash, color)
		for i in bomblets:
			var off := Vector2.from_angle(randf() * TAU) * randf_range(splash * 0.5, splash * 1.3)
			game.damage_area(target_pos + off, bomblet_splash, bomblet_damage, damage_type, hits_air, 0.0)
			game.spawn_blast(target_pos + off, bomblet_splash, color.lightened(0.3))
	elif is_instance_valid(target) and target.alive:
		target.take_damage(damage, damage_type)
		game.spawn_blast(target_pos, 8.0, color)
	queue_free()


func _draw() -> void:
	var outline := Color(0.11, 0.09, 0.14)
	match style:
		"shell":
			draw_circle(Vector2.ZERO, 7.0, outline)
			draw_circle(Vector2.ZERO, 5.0, Color(0.25, 0.25, 0.3))
			draw_circle(Vector2(-1, -1), 2.0, color)
		"pierce":
			draw_line(Vector2(-22, 0), Vector2(8, 0), Color(color, 0.35), 8.0)
			draw_line(Vector2(-14, 0), Vector2(10, 0), outline, 5.0)
			draw_line(Vector2(-12, 0), Vector2(9, 0), color.lightened(0.4), 3.0)
		_:
			draw_line(Vector2(-12, 0), Vector2(6, 0), Color(color, 0.35), 5.0)
			draw_line(Vector2(-8, 0), Vector2(6, 0), outline, 4.0)
			draw_line(Vector2(-7, 0), Vector2(5, 0), color, 2.0)
