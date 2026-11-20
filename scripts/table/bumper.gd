@tool
extends StaticBody2D
## Pop bumper: cuando la bola lo toca la despide hacia afuera y suma puntos.

@export var radius := 32.0:
	set(value):
		radius = value
		_rebuild()
@export var kick_speed := 1300.0
@export var points := 100
@export var color := Color(0.95, 0.35, 0.3)
@export var cap_color := Color(0.98, 0.9, 0.75)

var _shape_node: CollisionShape2D
var _flash := 0.0


func _ready() -> void:
	if not Engine.is_editor_hint():
		var mat := PhysicsMaterial.new()
		mat.bounce = 0.0
		physics_material_override = mat
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _shape_node == null:
		_shape_node = CollisionShape2D.new()
		add_child(_shape_node)
	var circle := CircleShape2D.new()
	circle.radius = radius
	_shape_node.shape = circle
	queue_redraw()


## Lo llama la bola desde su paso de física, al empezar el contacto.
func on_ball_contact(_ball: RigidBody2D, state: PhysicsDirectBodyState2D, _point: Vector2) -> void:
	var dir := (state.transform.origin - global_position).normalized()
	var v := state.linear_velocity
	var tangent := v - dir * v.dot(dir)
	state.linear_velocity = tangent * 0.5 + dir * kick_speed
	_flash = 1.0
	GameState.add_score.call_deferred(points, global_position)
	Input.vibrate_handheld(8)


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 5.0)
		queue_redraw()


func _draw() -> void:
	var glow := color.lightened(0.5 * _flash)
	if _flash > 0.0:
		draw_circle(Vector2.ZERO, radius + 14.0 * _flash, Color(glow, 0.35 * _flash))
	draw_circle(Vector2.ZERO, radius, glow)
	draw_circle(Vector2.ZERO, radius * 0.72, color.darkened(0.35))
	draw_circle(Vector2.ZERO, radius * 0.55, cap_color.lerp(Color.WHITE, _flash))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(1, 1, 1, 0.5), 2.0, true)
