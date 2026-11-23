@tool
extends StaticBody2D
## Gato de Cheshire: blanco circular que aparece y desaparece. El ciclo y el puntaje los lleva AliceRules;
## acá solo se apaga la colisión cuando está invisible (la bola lo atraviesa) y se anima el desvanecido.

## La bola golpeó el gato visible.
signal struck(at: Vector2)

const RADIUS := 32.0
const MIN_KICK := 520.0
## Segundos que tarda en aparecer o desvanecerse (sin parpadeos rápidos).
const FADE_SECONDS := 0.6

var shown := true
## 0..1 que se le pasa al dibujo: 1 visible, 0 solo la sonrisa.
var visibility := 1.0

@onready var _shape: CollisionShape2D = $Shape


func _ready() -> void:
	set_process(false)


## Lo llama AliceRules al cambiar de fase.
func set_shown(value: bool) -> void:
	shown = value
	if _shape:
		_shape.set_deferred("disabled", not value)
	set_process(not Engine.is_editor_hint())
	queue_redraw()


func on_ball_contact(_ball: RigidBody2D, state: PhysicsDirectBodyState2D, _point: Vector2) -> void:
	if not shown:
		return
	var normal := (state.transform.origin - global_position).normalized()
	state.linear_velocity = normal * maxf(MIN_KICK, state.linear_velocity.length() * 0.7)
	Settings.vibrate(14)
	struck.emit.call_deferred(global_position)


func _process(delta: float) -> void:
	visibility = move_toward(visibility, 1.0 if shown else 0.0, delta / FADE_SECONDS)
	queue_redraw()
	if is_equal_approx(visibility, 1.0 if shown else 0.0):
		set_process(false)


func _draw() -> void:
	AliceVisuals.draw_cheshire(self, RADIUS, visibility)
