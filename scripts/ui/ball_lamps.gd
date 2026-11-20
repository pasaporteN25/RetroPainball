@tool
extends Control
## Vidas como lamparitas en forma de bola: encendidas = bolas que quedan
## (incluida la que está en juego).

@export_range(1, 6) var total := 3:
	set(v):
		total = v
		queue_redraw()
@export var lit := 3:
	set(v):
		lit = v
		queue_redraw()
@export var on_color := Color(0.95, 0.95, 1.0)
@export var off_color := Color(1, 1, 1, 0.12)


func _draw() -> void:
	var r := minf(size.y * 0.5, size.x / (total * 2.6))
	var step := size.x / total
	for i in total:
		var c := Vector2(step * (i + 0.5), size.y * 0.5)
		var on := i < lit
		if on:
			draw_circle(c, r * 1.35, Color(on_color, 0.15))
			draw_circle(c, r, on_color)
			draw_circle(c + Vector2(-r, -r) * 0.3, r * 0.3, Color.WHITE)
		else:
			draw_arc(c, r, 0.0, TAU, 32, off_color, 2.0, true)
