class_name MonsterCorpse
extends Node2D
## A dying monster: plays the death animation of its rig, then frees itself.

const LIFE := 0.6

var rig: MonsterRig
var style := "biped"
var flying := false
var flip := 1.0
var unit := 1.0
var feet := Vector2.ZERO
var phase := 0.0
var t := 0.0
var color := Color.WHITE


func setup(e: Enemy) -> void:
	rig = e.rig
	style = rig.style
	flying = e.flying
	flip = e.flip
	unit = e.rig_scale()
	feet = e.feet()
	phase = e.walk_phase
	color = e.color
	position = e.position
	z_index = e.z_index


func _process(delta: float) -> void:
	t += delta
	if t >= LIFE:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var k := clampf(t / LIFE, 0.0, 1.0)
	var fall := ease(clampf(t / 0.3, 0.0, 1.0), 0.4)
	var alpha := 1.0 - smoothstep(0.45, 1.0, k)
	var flash := Color(1, 1, 1, 0.9 * (1.0 - clampf(t / 0.12, 0.0, 1.0)))
	if flash.a <= 0.0:
		flash = Color(color.lightened(0.3), 0.35 * k)
	var xf: Transform2D
	if flying:
		# tumble out of the air
		xf = Transform2D(-flip * fall * 1.4, Vector2(flip, 1.0) * unit, 0.0, feet + Vector2(0, 40.0 * k * k))
	elif style == "float":
		xf = Transform2D(0.0, Vector2(flip * (1.0 - 0.5 * k), 1.0 + 0.4 * k) * unit, 0.0, feet - Vector2(0, 18.0 * k))
	elif style == "worm":
		xf = Transform2D(0.0, Vector2(flip, 1.0 - 0.7 * k) * unit, 0.0, feet)
	else:
		# topple backwards onto the ground
		xf = Transform2D(-flip * fall * 1.35, Vector2(flip * (1.0 + 0.1 * fall), 1.0 - 0.1 * fall) * unit, 0.0, feet)
	rig.draw(self, xf, phase, t, 0.0, Color(1, 1, 1, alpha), flash)
	if k > 0.25:
		for i in 6:
			var a := TAU * i / 6.0 + i
			var r := 6.0 + 26.0 * k
			draw_circle(feet + Vector2(cos(a) * r, sin(a) * r * 0.4 - 10.0 * k - rig.height * unit * 0.3),
					2.5 * (1.0 - k) + 0.5, Color(color.lightened(0.4), alpha * 0.8))
