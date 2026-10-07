class_name Fx
extends Node2D
## Short-lived visual effects: blasts, pulse rings and floating text.

var kind := "blast"
var radius := 20.0
var color := Color.WHITE
var text := ""
var life := 0.35
var age := 0.0


static func make(kind_name: String, pos: Vector2, r: float, c: Color, duration: float = 0.35) -> Fx:
	var fx := Fx.new()
	fx.kind = kind_name
	fx.position = pos
	fx.radius = r
	fx.color = c
	fx.life = duration
	return fx


func _process(delta: float) -> void:
	age += delta
	if kind == "text":
		position.y -= delta * 40.0
	if age >= life:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var t := clampf(age / life, 0.0, 1.0)
	match kind:
		"blast":
			draw_circle(Vector2.ZERO, radius * (0.4 + 0.6 * t), Color(color, 0.55 * (1.0 - t)))
			draw_circle(Vector2.ZERO, radius * 0.35 * (1.0 - t), Color(1, 1, 0.9, 0.9 * (1.0 - t)))
		"ring":
			draw_arc(Vector2.ZERO, radius * (0.2 + 0.8 * t), 0, TAU, 48, Color(color, 0.8 * (1.0 - t)), 4.0)
			draw_circle(Vector2.ZERO, radius * (0.2 + 0.8 * t), Color(color, 0.12 * (1.0 - t)))
		"text":
			var font := ThemeDB.fallback_font
			draw_string_outline(font, Vector2(-40, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 80, 20, 5, Color(0.11, 0.09, 0.14, 1.0 - t))
			draw_string(font, Vector2(-40, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 80, 20, Color(color, 1.0 - t))
