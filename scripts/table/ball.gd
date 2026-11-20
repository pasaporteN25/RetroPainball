extends RigidBody2D
## La bola. Avisa a lo que toca (bumpers, slingshots) llamando a
## on_ball_contact() en el objeto chocado, y limita su velocidad máxima.

const RADIUS := 16.0
const TRAIL_LIFETIME := 0.065
const TRAIL_SAMPLE_INTERVAL := 0.011
const TRAIL_SAMPLE_LIMIT := 7

@export var max_speed := 4200.0
@export var color := Color("#c3d8e0")

## Objetos que la bola tocaba en el paso de física anterior. Sirve para
## avisar solo cuando un contacto empieza y no en cada paso.
var _touching := {}
var _trail_positions := PackedVector2Array()
var _trail_times := PackedFloat32Array()
var _trail_clock := 0.0
var _last_sample_at := -TRAIL_SAMPLE_INTERVAL


func _init() -> void:
	can_sleep = false
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	contact_monitor = true
	max_contacts_reported = 6
	collision_layer = 2
	collision_mask = 1 | 2
	var mat := PhysicsMaterial.new()
	mat.bounce = 0.2
	mat.friction = 0.25
	physics_material_override = mat
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var now := {}
	for i in state.get_contact_count():
		var obj := state.get_contact_collider_object(i)
		if obj == null:
			continue
		var id := obj.get_instance_id()
		if now.has(id):
			continue
		now[id] = true
		if not _touching.has(id) and obj.has_method("on_ball_contact"):
			obj.on_ball_contact(self, state, state.get_contact_collider_position(i))
	_touching = now
	if state.linear_velocity.length() > max_speed:
		state.linear_velocity = state.linear_velocity.limit_length(max_speed)


func _process(delta: float) -> void:
	_trail_clock += delta
	if not _trail_positions.is_empty() and _trail_positions[-1].distance_to(global_position) > 180.0:
		_trail_positions.clear()
		_trail_times.clear()
	if _trail_clock - _last_sample_at >= TRAIL_SAMPLE_INTERVAL and linear_velocity.length_squared() > 560.0 ** 2:
		_trail_positions.append(global_position)
		_trail_times.append(_trail_clock)
		_last_sample_at = _trail_clock
	while not _trail_times.is_empty() and (_trail_times.size() > TRAIL_SAMPLE_LIMIT or _trail_clock - _trail_times[0] > TRAIL_LIFETIME):
		_trail_positions.remove_at(0)
		_trail_times.remove_at(0)
	queue_redraw()


func _draw() -> void:
	var next := Vector2.ZERO
	for i in range(_trail_positions.size() - 1, -1, -1):
		var point := to_local(_trail_positions[i])
		var freshness := clampf(1.0 - (_trail_clock - _trail_times[i]) / TRAIL_LIFETIME, 0.0, 1.0)
		draw_line(point, next, Color(0.3, 0.95, 0.86, freshness * 0.22), 3.0 + freshness * 15.0, true)
		draw_line(point, next, Color(0.82, 1.0, 0.96, freshness * 0.40), 1.0 + freshness * 3.0, true)
		next = point
	# El reflejo se orienta hacia la luz de la mesa, independientemente del giro.
	draw_set_transform(Vector2.ZERO, -global_rotation)
	draw_circle(Vector2(4, 7), RADIUS + 4.0, Color(0.01, 0.03, 0.05, 0.28), true, -1.0, true)
	draw_circle(Vector2(3, 5), RADIUS + 1.0, Color(0.01, 0.03, 0.05, 0.64), true, -1.0, true)
	draw_circle(Vector2.ZERO, RADIUS, color.darkened(0.82), true, -1.0, true)
	draw_circle(Vector2(-0.8, -1.4), RADIUS - 1.5, color.darkened(0.31), true, -1.0, true)
	draw_circle(Vector2(-2.5, -3.5), 11.8, color, true, -1.0, true)
	draw_circle(Vector2(-4, -5), 8.5, color.lightened(0.46), true, -1.0, true)
	draw_arc(Vector2(0.5, -0.8), 13.1, 0.28, 2.22, 16, Color("#ecb980"), 1.7, true)
	draw_arc(Vector2.ZERO, 14.5, 3.4, 5.25, 16, Color("#eaf9ff"), 1.5, true)
	draw_circle(Vector2(-5.5, -6.7), 3.5, Color("#ffffff"), true, -1.0, true)
