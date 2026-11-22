extends RefCounted
## Viñeta original del castillo para el selector.

static var BAT := PackedVector2Array([Vector2(-18, -4), Vector2(-11, -9), Vector2(-4, -4), Vector2(0, -8), Vector2(4, -4), Vector2(11, -9), Vector2(18, -4), Vector2(12, 5), Vector2(7, 2), Vector2(4, 7), Vector2(0, 4), Vector2(-4, 7), Vector2(-7, 2), Vector2(-12, 5)])

static func draw(card: Control, rect: Rect2) -> void:
	card.draw_rect(rect, Color("#1b2140"))
	var c := rect.get_center()
	var scale_factor := minf(rect.size.x / 400.0, rect.size.y / 200.0)
	card.draw_set_transform(c, 0, Vector2.ONE * scale_factor)
	for i in 4:
		card.draw_circle(Vector2(35, -30), 69 - i * 6, Color(0.79, 0.83, 0.9, 0.035), true, -1, true)
	card.draw_circle(Vector2(35, -30), 43, Color("#c9d3e6"), true, -1, true)
	var castle := PackedVector2Array([Vector2(-135, 90), Vector2(-135, 19), Vector2(-115, 19), Vector2(-115, -19), Vector2(-99, -43), Vector2(-83, -19), Vector2(-83, 8), Vector2(-58, 8), Vector2(-58, -10), Vector2(-42, -10), Vector2(-42, -34), Vector2(-23, -60), Vector2(-4, -34), Vector2(-4, 8), Vector2(28, 8), Vector2(28, 21), Vector2(59, 21), Vector2(59, -12), Vector2(75, -36), Vector2(91, -12), Vector2(91, 28), Vector2(119, 28), Vector2(119, 90)])
	card.draw_colored_polygon(castle, Color("#0b0a14"))
	card.draw_polyline(castle, Color(0.79, 0.83, 0.9, 0.3), 2, true)
	card.draw_rect(Rect2(-27, -28, 8, 15), Color("#c9a35a"))
	card.draw_set_transform(c + Vector2(110, -55) * scale_factor, 0, Vector2.ONE * scale_factor)
	card.draw_colored_polygon(BAT, Color("#0b0a14"))
	card.draw_set_transform(Vector2.ZERO)
