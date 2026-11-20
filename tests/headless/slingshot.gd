extends SceneTree
## Usa el motor de física y los slings de ambas mesas. Un tiro casi horizontal
## desde el centro reproducía el ida y vuelta entre los triángulos.

const Ball := preload("res://scripts/table/ball.gd")
const SCENES := ["res://scenes/main.tscn", "res://scenes/nautilus.tscn"]

var _game_state: Node
var _left_contact := Vector2.ZERO
var _right_contact := Vector2.ZERO
var _kicks: Array[int] = []
var _failures := 0
var _checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_game_state = root.get_node("GameState")
	_game_state.save_directory = ""
	_game_state.record_path = "user://test_slingshot_%d.cfg" % OS.get_process_id()
	_game_state.scored.connect(_on_scored)
	for path in SCENES:
		await _test_table(path)
	if FileAccess.file_exists(_game_state.record_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_game_state.record_path))
	print("Slingshots: %d controles / %d fallos" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _test_table(path: String) -> void:
	var game := (load(path) as PackedScene).instantiate()
	root.add_child(game)
	var table := game.get_node("Table")
	var left := _rubber_face(table.get_node("LeftSlingshot/Shape"))
	var right := _rubber_face(table.get_node("RightSlingshot/Shape"))
	_left_contact = left[0].lerp(left[1], 0.5)
	_right_contact = right[0].lerp(right[1], 0.5)
	var middle := _left_contact.lerp(_right_contact, 0.5)
	var name := "Nautilus" if path.ends_with("nautilus.tscn") else "Kernel Panic"
	await _test_two_balls(table, left, right, middle, name)
	for heading in [-1, 1]:
		await _test_crossing(table, left, right, middle, heading, name)
	game.queue_free()
	await process_frame


func _test_two_balls(table: Node2D, left: PackedVector2Array, right: PackedVector2Array,
		middle: Vector2, name: String) -> void:
	_kicks.clear()
	var left_n := _inward_normal(left, middle)
	var right_n := _inward_normal(right, middle)
	var left_ball := _spawn(table, _left_contact + left_n * 42.0, -left_n * 650.0)
	var right_ball := _spawn(table, _right_contact + right_n * 42.0, -right_n * 650.0)
	for step in 36:
		await physics_frame
		if _kicks.has(-1) and _kicks.has(1):
			break
	_check(_kicks.has(-1) and _kicks.has(1),
		"%s: dos bolas pueden activar los dos slings en el mismo cruce" % name)
	_check(left_ball.linear_velocity.dot(left_n) > 520.0
		and right_ball.linear_velocity.dot(right_n) > 520.0,
		"%s: las gomas conservan un impulso activo" % name)
	left_ball.queue_free()
	right_ball.queue_free()
	await process_frame


func _test_crossing(table: Node2D, left: PackedVector2Array, right: PackedVector2Array,
		middle: Vector2, heading: int, name: String) -> void:
	_kicks.clear()
	var top := minf(left[0].y, right[0].y) - 2.0 * Ball.RADIUS
	var bottom := maxf(left[1].y, right[1].y) + 2.0 * Ball.RADIUS
	var x_min := minf(left[0].x, left[1].x) - 2.0 * Ball.RADIUS
	var x_max := maxf(right[0].x, right[1].x) + 2.0 * Ball.RADIUS
	var lower_field := Rect2(Vector2(x_min, top), Vector2(x_max - x_min, bottom - top))
	var ball := _spawn(table, middle, Vector2(900.0 * heading, 0.0))
	var escaped := false
	for step in 480:
		await physics_frame
		if not is_instance_valid(ball) or not lower_field.has_point(ball.global_position):
			escaped = true
			break
	var side := "izquierda" if heading < 0 else "derecha"
	_check(_kicks.has(heading), "%s: el tiro a la %s activa la goma" % [name, side])
	_check(escaped and _kicks.size() <= 4, "%s: el tiro a la %s sale de la zona tras %d impulsos"
		% [name, side, _kicks.size()])
	if is_instance_valid(ball):
		ball.queue_free()
	await process_frame


func _spawn(table: Node2D, at: Vector2, velocity: Vector2) -> RigidBody2D:
	var ball := Ball.new()
	ball.position = table.to_local(at)
	ball.linear_velocity = velocity
	table.get_node("Balls").add_child(ball)
	return ball


func _rubber_face(shape: CollisionPolygon2D) -> PackedVector2Array:
	return PackedVector2Array([shape.to_global(shape.polygon[0]), shape.to_global(shape.polygon[1])])


func _inward_normal(face: PackedVector2Array, middle: Vector2) -> Vector2:
	var normal := (face[1] - face[0]).orthogonal().normalized()
	return normal if normal.dot(middle - face[0]) > 0.0 else -normal


func _on_scored(_points: int, at: Vector2) -> void:
	if at.is_equal_approx(_left_contact):
		_kicks.append(-1)
	elif at.is_equal_approx(_right_contact):
		_kicks.append(1)


func _check(ok: bool, description: String) -> void:
	_checks += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", description])
	if not ok:
		_failures += 1
