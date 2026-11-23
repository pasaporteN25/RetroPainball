extends SceneTree
## G-12: el kickback devuelve la bola del outlane izquierdo una vez por bola y se rearma al perderla.

const Ball := preload("res://scripts/table/ball.gd")
const TABLES := ["res://scenes/main.tscn", "res://scenes/nautilus.tscn", "res://scenes/dracula.tscn", "res://scenes/alicia.tscn"]

var _state: Node
var _table: Node2D
var _checks := 0
var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_state = root.get_node("GameState")
	_state.save_directory = ""
	_state.record_path = "user://test_kickback_%d.cfg" % OS.get_process_id()
	for path in TABLES:
		change_scene_to_file(path)
		await scene_changed
		_table = current_scene.get_node("Table")
		await _test_kickback()
	print("Kickback: %d controles / %d fallos" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _test_kickback() -> void:
	var label: String = _state.table_id
	await create_timer(1.0).timeout
	for ball in _table.get_node("Balls").get_children():
		ball.queue_free()
	_check(_state.kickback_ready, "%s: el kickback arranca listo" % label)
	var balls_before: int = _state.balls_left

	var first := _spawn(Vector2(40, 1030), Vector2(0, 500))
	var highest := 9999.0
	for i in 120:
		await physics_frame
		if is_instance_valid(first):
			highest = minf(highest, first.position.y)
	_check(is_instance_valid(first) and not first.is_queued_for_deletion() and highest < 950.0,
		"%s: el kickback devuelve la bola al tablero" % label)
	_check(not _state.kickback_ready, "%s: el kickback se gasta" % label)
	_check(_state.balls_left == balls_before, "%s: la bola devuelta no cuesta una bola" % label)
	if is_instance_valid(first):
		first.queue_free()

	# Sin kickback la bola drena y, al perderla, se rearma para la bola siguiente.
	var second := _spawn(Vector2(40, 1030), Vector2(0, 500))
	for i in 360:
		await physics_frame
		if not is_instance_valid(second) or second.is_queued_for_deletion():
			break
	var drained := not is_instance_valid(second) or second.is_queued_for_deletion()
	_check(drained, "%s: gastado, la segunda bola drena por el outlane" % label)
	await physics_frame
	_check(_state.balls_left == balls_before - 1 and _state.kickback_ready,
		"%s: al perder la bola el kickback se rearma" % label)
	for ball in _table.get_node("Balls").get_children():
		ball.queue_free()


func _spawn(at: Vector2, velocity: Vector2) -> RigidBody2D:
	var ball := Ball.new()
	ball.position = at
	ball.linear_velocity = velocity
	_table.get_node("Balls").add_child(ball)
	return ball


func _check(ok: bool, description: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", description])
