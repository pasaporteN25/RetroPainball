@tool
extends Control
## Indicadores iluminados de las bolas que quedan, incluida la bola actual.

@export_range(1, 6) var total := 3:
	set(v):
		total = v
		queue_redraw()

@export var lit := 3:
	set(v):
		lit = v
		queue_redraw()

@export var on_color := Color("#75e6c6")
@export var off_color := Color("#304341")


func _draw() -> void:
	var r := minf(size.y * 0.45, size.x / (total * 2.55))
	var step := size.x / total
	for i in total:
		var center := Vector2(step * (i + 0.5), size.y * 0.5)
		var on := i < lit
		if on:
			draw_circle(center, r * 1.27, Color(on_color, 0.10), true, -1.0, true)
		draw_circle(center, r, Color("#030808"), true, -1.0, true)
		draw_arc(center, r * 0.88, 0.0, TAU, 32, Color("#566362"), 1.0, true)
		draw_circle(center, r * 0.65, on_color.darkened(0.2) if on else off_color, true, -1.0, true)
		if on:
			draw_circle(center + Vector2(-r, -r) * 0.18, r * 0.35, on_color.lightened(0.56), true, -1.0, true)
