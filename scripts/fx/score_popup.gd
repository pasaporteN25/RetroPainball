extends Node2D
## Número que salta desde donde se sumaron los puntos y se desvanece.
## Cuantos más puntos, más grande.

var text := ""
var color := Color(1.0, 0.85, 0.3)
var font_size := 30


func setup(points: int, at: Vector2, tint: Color) -> void:
	text = str(points)
	position = at
	color = tint
	font_size = 26 + int(6.0 * log(maxf(points, 1.0)) / log(10.0))


func _ready() -> void:
	scale = Vector2(0.4, 0.4)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y - 70.0, 0.75).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.35).set_delay(0.4)
	tween.chain().tween_callback(queue_free)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var at := Vector2(-w * 0.5, font_size * 0.35)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6, Color(0, 0, 0, 0.8))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
