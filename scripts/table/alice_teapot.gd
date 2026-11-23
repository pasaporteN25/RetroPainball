@tool
extends StaticBody2D
## Tetera: blanco circular grande. En Té Loco paga el jackpot (lo decide AliceRules).

## La bola golpeó la tetera.
signal struck(at: Vector2)

const RADIUS := 55.0
const MIN_KICK := 620.0

## Lo enciende AliceRules mientras dura Té Loco.
var jackpot_ready := false:
	set(value):
		jackpot_ready = value
		queue_redraw()


func _ready() -> void:
	if not Engine.is_editor_hint():
		var mat := PhysicsMaterial.new()
		mat.bounce = 0.0
		physics_material_override = mat


func on_ball_contact(_ball: RigidBody2D, state: PhysicsDirectBodyState2D, _point: Vector2) -> void:
	var normal := (state.transform.origin - global_position).normalized()
	var tangent := normal.orthogonal()
	var glancing := state.linear_velocity.dot(tangent)
	state.linear_velocity = normal * maxf(MIN_KICK, -state.linear_velocity.dot(normal) * 0.6) + tangent * glancing * 0.7
	Settings.vibrate(14 if jackpot_ready else 8)
	struck.emit.call_deferred(global_position)


func _draw() -> void:
	AliceVisuals.draw_teapot(self, RADIUS, jackpot_ready)
