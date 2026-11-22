extends Node2D
## Agua y partículas reutilizadas, detrás de las piezas de la mesa.

const COUNT := 24
var _positions := PackedVector2Array()
var _speeds := PackedFloat32Array()
var _radii := PackedFloat32Array()
var _time := 0.0
var _redraw_time := 0.0


func _ready() -> void:
	for i in COUNT:
		_positions.append(Vector2(95.0 + fposmod(i * 137.0, 530.0), 320.0 + fposmod(i * 173.0, 1000.0)))
		_speeds.append(8.0 + fposmod(i * 7.0, 13.0))
		_radii.append(1.8 + fposmod(i * 3.0, 3.0))
	set_process(not Engine.is_editor_hint())


func _process(delta: float) -> void:
	_time = fposmod(_time + delta, 1000.0)
	for i in COUNT:
		var p := _positions[i]
		p.y -= _speeds[i] * delta
		if p.y < 305.0:
			p.y = 1320.0
		_positions[i] = p
	_redraw_time += delta
	if _redraw_time >= 1.0 / 30.0:
		_redraw_time = 0.0
		queue_redraw()


func _draw() -> void:
	for i in 4:
		var x := 120.0 + i * 155.0 + sin(_time * 0.11 + i) * 22.0
		draw_line(Vector2(x, 310), Vector2(x + 95, 1120), Color(0.48, 0.95, 0.9, 0.035), 24.0, true)
		draw_line(Vector2(x + 12, 350), Vector2(x + 75, 980), Color(0.7, 1.0, 0.95, 0.035), 3.0, true)
	for i in _positions.size():
		var p := _positions[i] + Vector2(sin(_time * 0.45 + i) * 9.0, 0)
		draw_circle(p, _radii[i], Color(0.65, 1.0, 0.95, 0.22), false, 1.0, true)
