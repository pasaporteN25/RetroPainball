@tool
extends StaticBody2D
## Blanco BEBÉ-ME (kind 0, achica) o CÓMEME (kind 1, agranda) en la pared. Solo avisa; AliceRules cambia el tamaño.

## La bola golpeó el blanco (`kind` = AliceVisuals.SIZE_DRINK o SIZE_EAT).
signal hit(kind: int)

const RADIUS := 20.0
## Segundos sin volver a contar golpes (una bola que rebota contra el blanco no lo alterna varias veces).
const COOLDOWN := 0.8

@export_enum("BEBÉ-ME:0", "CÓMEME:1") var kind := 0:
	set(value):
		kind = value
		queue_redraw()

## true si es el tamaño actual (lo pone AliceRules).
var active := false:
	set(value):
		active = value
		queue_redraw()


var _last_hit := -100.0


func on_ball_contact(_ball: RigidBody2D, _state: PhysicsDirectBodyState2D, _point: Vector2) -> void:
	if GameState.playing:
		strike.call_deferred()


## Registra el golpe. Público para poder probarlo sin física.
func strike() -> void:
	if not GameState.playing:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_hit < COOLDOWN:
		return
	_last_hit = now
	Settings.vibrate(10)
	hit.emit(kind)


func _draw() -> void:
	AliceVisuals.draw_size_target(self, kind, active, RADIUS)
