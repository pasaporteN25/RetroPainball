extends Node2D
## Indicador flotante de puntos, con el formato de las placas de la mesa.

var text := ""
var color := Color(1.0, 0.85, 0.3)
var font_size := 28
var duration := 0.70
var font: Font
var plate_color := Color("#0c141d")
var border_color := Color.WHITE


func setup(points: int, at: Vector2, _tint: Color) -> void:
	text = "+%d" % points
	position = at - Vector2(0.0, 32.0)
	# Las fuentes del sistema tienen alternativas genéricas para Android y PC.
	var themed_font := SystemFont.new()
	if (Engine.get_main_loop() as SceneTree).root.get_node("GameState").table_id == "nautilus":
		themed_font.font_names = PackedStringArray(["serif"])
		color = Color("#78e4db")
		plate_color = Color("#302719")
		border_color = Color("#c5a15b")
	else:
		themed_font.font_names = PackedStringArray(["monospace"])
		color = Color("#83ff91")
		plate_color = Color("#071b0d")
		border_color = color
	font = themed_font
	duration = 1.05 if points >= 1000 else 0.70
	font_size = 21 + int(6.0 * log(maxf(points, 1.0)) / log(10.0))
	var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var margin := text_width * 0.5 + 28.0
	position.x = clampf(position.x, 16.0 + margin, 656.0 - margin)


func _ready() -> void:
	scale = Vector2(0.68, 0.68)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.17).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y - 74.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.32).set_delay(duration - 0.32)
	tween.chain().tween_callback(queue_free)


func _draw() -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var edge := w * 0.5 + 17.0
	var h := font_size * 0.5 + 5.0
	var plate := PackedVector2Array([
		Vector2(-edge, -h + 7), Vector2(-edge + 7, -h), Vector2(edge, -h),
		Vector2(edge, h - 7), Vector2(edge - 7, h), Vector2(-edge, h),
	])
	draw_colored_polygon(plate, plate_color)
	plate.append(plate[0])
	draw_polyline(plate, Color(border_color, 0.78), 2.0, true)
	draw_line(Vector2(-edge + 4, -h + 10), Vector2(-edge + 4, h - 4), color, 2.0, true)
	draw_string(font, Vector2(-w * 0.5, font_size * 0.35), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color.lightened(0.25))
