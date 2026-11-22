extends Node2D
## Brief, self-contained terminal error at the drain.

var _elapsed := 0.0

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= 1.1:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var alpha := minf(1.0, (1.1 - _elapsed) * 2.0) * 0.75
	var offset := sin(_elapsed * 11.0) * 3.0 * (1.0 - _elapsed / 1.1)
	var tint := Color(0.41, 0.89, 0.69, alpha)
	draw_string(ThemeDB.fallback_font, Vector2(291 + offset, 1301), "SEGFAULT", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, tint)
	draw_line(Vector2(280 - offset, 1306), Vector2(322 - offset, 1306), Color(tint, alpha * 0.55), 1.0)
	draw_line(Vector2(350 + offset, 1309), Vector2(392 + offset, 1309), Color(tint, alpha * 0.55), 1.0)
