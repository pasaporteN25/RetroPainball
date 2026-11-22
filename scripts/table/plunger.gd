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
@export var color := Color("#829aa0")
## G-09: ventana de potencia (0..1) del skill shot; se marca en las lámparas del lanzador.
@export_range(0.0, 1.0) var skill_min := 0.70
@export_range(0.0, 1.0) var skill_max := 0.90

var charge := 0.0
var _charging := false
var _sensor: Area2D
var _displayed_charge := -1.0
var _displayed_ready := false
var _launch_flash := 0.0


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


func in_skill_window(power: float) -> bool:
	return power >= skill_min and power <= skill_max


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


func _process(delta: float) -> void:
	var ready_ball := GameState.ball_in_lane
	if _launch_flash > 0.0 or charge != _displayed_charge or ready_ball != _displayed_ready:
		_launch_flash = maxf(0.0, _launch_flash - delta * 4.0)
		_displayed_charge = charge
		_displayed_ready = ready_ball
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
	_launch_flash = 1.0
	Input.vibrate_handheld(20)
	launched.emit(power)


func _draw() -> void:
	var offset := charge * travel
	var half := lane_width * 0.5 - 3.0
	var bottom := 116.0
	var light := Color("#5dcabc").lerp(Color("#ffad58"), charge)
	draw_rect(Rect2(-half, 0.0, half * 2.0, bottom + 12.0), Color("#0b1219"))
	draw_rect(Rect2(-half + 1.0, 5.0, 1.0, bottom - 2.0), Color("#244452"))
	draw_rect(Rect2(half - 2.0, 5.0, 1.0, bottom - 2.0), Color("#41616a"))
	draw_rect(Rect2(-4.0, 8.0, 8.0, bottom - 7.0), color.darkened(0.72))
	draw_rect(Rect2(-2.0, 8.0, 2.0, bottom - 7.0), color.darkened(0.2))
	_draw_spring(offset + 13.0, bottom, half * 0.46, light)
	draw_rect(Rect2(-half + 2.0, offset, half * 2.0 - 4.0, 12.0), color.darkened(0.65))
	draw_rect(Rect2(-half + 3.0, offset + 1.0, half * 2.0 - 6.0, 4.0), color)
	draw_rect(Rect2(-half + 5.0, offset + 1.0, half * 2.0 - 10.0, 1.0), color.lightened(0.5))
	for i in 8:
		var y := bottom - 5.0 - i * 10.0
		var level := clampf(charge * 8.0 - i, 0.0, 1.0)
		var lamp := Color("#193337").lerp(light, level)
		draw_rect(Rect2(half - 7.0, y, 3.0, 6.0), lamp)
	# Ventana del skill shot: marco dorado junto a las lámparas, a la altura de su potencia.
	var band_low := bottom - 5.0 - skill_min * 80.0
	var band_high := bottom - 5.0 - skill_max * 80.0
	var in_band := in_skill_window(charge)
	var gold := Color("#ffd35c") if in_band else Color("#a88a3a")
	draw_rect(Rect2(half - 10.0, band_high, 9.0, band_low - band_high + 6.0), Color(gold, 0.9), false, 1.5)
	draw_rect(Rect2(-half + 1.0, bottom, half * 2.0 - 2.0, 10.0), color.darkened(0.50))
	draw_rect(Rect2(-half + 3.0, bottom, half * 2.0 - 6.0, 2.0), color)
	draw_rect(Rect2(-half + 4.0, bottom + 4.0, 5.0, 3.0), light if _displayed_ready else Color("#243e42"))
	if _launch_flash > 0.0:
		draw_rect(Rect2(-half + 2.0, -32.0 * _launch_flash, half * 2.0 - 4.0, 35.0), Color(light, _launch_flash * 0.30))


func _draw_spring(top: float, bottom: float, half: float, light: Color) -> void:
	var coils := PackedVector2Array()
	for i in 15:
		var x := -half if i % 2 == 0 else half
		coils.append(Vector2(x, lerpf(top, bottom, i / 14.0)))
	draw_polyline(coils, Color("#0a1116"), 4.2, true)
	draw_polyline(coils, color.lerp(light, charge), 2.3, true)
