extends Node2D
## Lanzador. Mantener "launch" carga y soltar dispara. El nodo se ubica en el
## centro del carril, a la altura donde se apoya la bola.

signal launched(power: float)

@export var lane_width := 44.0
@export var min_speed := 1200.0
@export var max_speed := 3000.0
## Segundos para llegar a carga completa.
@export var charge_time := 0.9
## Recorrido visual del resorte con carga completa.
@export var travel := 46.0
@export var color := Color(0.75, 0.75, 0.8)

var charge := 0.0
var _charging := false
var _sensor: Area2D


func _ready() -> void:
	var body := StaticBody2D.new()
	var body_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(lane_width, 40.0)
	body_shape.shape = rect
	body_shape.position = Vector2(0.0, 20.0)
	body.add_child(body_shape)
	add_child(body)

	_sensor = Area2D.new()
	_sensor.collision_layer = 0
	_sensor.collision_mask = 2
	var sensor_shape := CollisionShape2D.new()
	var sensor_rect := RectangleShape2D.new()
	sensor_rect.size = Vector2(lane_width, 60.0)
	sensor_shape.shape = sensor_rect
	sensor_shape.position = Vector2(0.0, -30.0)
	_sensor.add_child(sensor_shape)
	add_child(_sensor)


func has_ball() -> bool:
	return not _sensor.get_overlapping_bodies().is_empty()


func _physics_process(delta: float) -> void:
	var ready_ball := has_ball()
	GameState.ball_in_lane = ready_ball
	GameState.plunger_charge = charge
	var pressed := Input.is_action_pressed("launch")
	if pressed and ready_ball:
		_charging = true
		charge = minf(1.0, charge + delta / charge_time)
	elif _charging and not pressed:
		_fire()
	elif not pressed:
		charge = move_toward(charge, 0.0, delta * 6.0)
	queue_redraw()


func _fire() -> void:
	_charging = false
	var power := charge
	var speed := lerpf(min_speed, max_speed, power)
	for body in _sensor.get_overlapping_bodies():
		var ball := body as RigidBody2D
		if ball:
			ball.linear_velocity = Vector2(0.0, -speed)
	charge = 0.0
	Input.vibrate_handheld(20)
	launched.emit(power)


func _draw() -> void:
	var offset := charge * travel
	var half := lane_width * 0.5 - 4.0
	# Resorte: se comprime y se pone naranja con la carga.
	var spring_color := Color(0.5, 0.5, 0.55).lerp(Color(1.0, 0.45, 0.1), charge)
	var coils := 6
	var top := offset + 10.0
	var bottom := 120.0
	for i in coils:
		var y0 := lerpf(top, bottom, float(i) / coils)
		var y1 := lerpf(top, bottom, float(i + 1) / coils)
		draw_line(Vector2(-half, y0), Vector2(half, (y0 + y1) * 0.5), spring_color, 3.0, true)
		draw_line(Vector2(half, (y0 + y1) * 0.5), Vector2(-half, y1), spring_color, 3.0, true)
	# Cabeza
	draw_rect(Rect2(-half, offset, half * 2.0, 10.0), color)
