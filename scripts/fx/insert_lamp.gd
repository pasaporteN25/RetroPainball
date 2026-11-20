extends RefCounted
## Dibuja el vidrio y el halo del inserto en el mismo lienzo de la pieza.


static func draw(on: CanvasItem, at: Vector2, radius: float, tint: Color, level: float) -> void:
	if level > 0.0:
		on.draw_circle(at, radius * 1.75, Color(tint, 0.17 * level), true, -1, true)
	on.draw_circle(at, radius + 1.5, Color("#08151d"), true, -1, true)
	on.draw_circle(at, radius, tint.darkened(0.81).lerp(tint, level), true, -1, true)
	if level > 0.0:
		on.draw_circle(at - Vector2.ONE * radius * 0.17, radius * 0.45,
			Color(tint.lightened(0.65), level), true, -1, true)
