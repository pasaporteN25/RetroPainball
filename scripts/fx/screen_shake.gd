extends Node
## Mueve el lienzo de la mesa durante un golpe fuerte. El HUD queda fijo.

const MIN_STRENGTH := 1250.0
const MAX_AMPLITUDE := 4.0
const DURATION := 0.11
const RECOVERY := 0.17

var _direction := Vector2.ZERO
var _amplitude := 0.0
var _elapsed := 0.0
var _offset := Vector2.ZERO


## La velocidad del punto de contacto conserva el golpe previo al rebote.
static func contact_strength(state: PhysicsDirectBodyState2D, piece: Node2D, normal: Vector2) -> float:
	var speed := 0.0
	for i in state.get_contact_count():
		if state.get_contact_collider_object(i) == piece:
			speed = maxf(speed, absf(state.get_contact_local_velocity_at_position(i).dot(normal)))
	return speed


func _ready() -> void:
	set_process(false)
	GameState.game_started.connect(_stop)


func on_impact(strength: float, direction: Vector2) -> void:
	if not GameState.playing or not can_process() or is_processing() or strength < MIN_STRENGTH:
		return
	_direction = direction
	_amplitude = lerpf(2.0, MAX_AMPLITUDE, clampf((strength - MIN_STRENGTH) / 950.0, 0.0, 1.0))
	_elapsed = 0.0
	set_process(true)


func _process(delta: float) -> void:
	_elapsed += delta
	var t := minf(_elapsed / DURATION, 1.0)
	_apply_offset(_direction * roundf(_amplitude * sin(TAU * t) * (1.0 - t)))
	if _elapsed >= DURATION + RECOVERY:
		_stop()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		_stop()


func _exit_tree() -> void:
	_apply_offset(Vector2.ZERO)


func _stop() -> void:
	_apply_offset(Vector2.ZERO)
	set_process(false)


func _apply_offset(next_offset: Vector2) -> void:
	if next_offset == _offset:
		return
	var viewport := get_viewport()
	var canvas := viewport.canvas_transform
	canvas.origin += next_offset - _offset
	viewport.canvas_transform = canvas
	_offset = next_offset
