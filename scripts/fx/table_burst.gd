extends Node2D
## Destellos breves de la mesa. Las chispas se dibujan en una sola capa.

const SPARK_LIFETIME := 0.29
const MAX_SPARKS := 8

var _elapsed := 0.0
var _radius := 0.0
var _tint := Color.WHITE
var _velocities := PackedVector2Array()


func setup(at: Vector2, tint: Color, radius: float, count: int, direction := Vector2.ZERO) -> void:
	position = at
	_tint = tint
	_radius = radius
	count = clampi(count, 0, MAX_SPARKS)
	_velocities.resize(count)
	var phase := randf() * TAU
	for i in count:
		var angle := TAU * i / count + phase
		var velocity := Vector2.from_angle(angle) * randf_range(90.0, 245.0)
		_velocities[i] = velocity + direction


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= SPARK_LIFETIME:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var t := clampf(_elapsed / SPARK_LIFETIME, 0.0, 1.0)
	var alpha := pow(1.0 - t, 1.8)
	var ring := _radius + ease(t, 0.55) * 36.0
	var flash := maxf(1.0 - _elapsed / 0.075, 0.0)
	if flash > 0.0:
		draw_circle(Vector2.ZERO, _radius + 6.0, Color(_tint, flash * 0.25), true, -1, true)
	draw_arc(Vector2.ZERO, ring, 0, TAU, 24, Color(_tint, alpha * 0.18), 8.0, true)
	draw_arc(Vector2.ZERO, ring, 0, TAU, 24, Color(_tint.lightened(0.25), alpha * 0.88), 2.0, true)
	var spark_color := Color(_tint.lerp(Color.WHITE, 0.6), alpha)
	for velocity in _velocities:
		var start := velocity.normalized() * _radius
		var tip := start + velocity * _elapsed * (1.0 - t * 0.42)
		var tail := tip - velocity * (0.018 + alpha * 0.022)
		draw_line(tail, tip, spark_color, 1.5 + alpha, true)
