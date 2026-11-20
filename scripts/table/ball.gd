extends RigidBody2D
## La bola. Avisa a lo que toca (bumpers, slingshots) llamando a
## on_ball_contact() en el objeto chocado, y limita su velocidad máxima.

const RADIUS := 16.0

@export var max_speed := 4200.0
@export var color := Color(0.85, 0.87, 0.92)

## Objetos que la bola tocaba en el paso de física anterior. Sirve para
## avisar solo cuando un contacto empieza y no en cada paso.
var _touching := {}


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


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	# El brillo no gira con la bola: se dibuja en coordenadas sin rotación.
	draw_set_transform(Vector2.ZERO, -global_rotation)
	draw_circle(Vector2.ZERO, RADIUS, color)
	draw_circle(Vector2(2, 3), RADIUS * 0.8, color.darkened(0.12))
	draw_circle(Vector2(-5, -5), RADIUS * 0.32, Color(1, 1, 1, 0.85))
