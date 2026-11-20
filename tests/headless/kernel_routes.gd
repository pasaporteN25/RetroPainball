extends SceneTree
## Prueba recorridos y blancos de Kernel Panic usando cuerpos físicos reales.

const Ball := preload("res://scripts/table/ball.gd")
const SCENE := "res://scenes/main.tscn"

var _state: Node
var _layout: Node
var _balls: Node2D
var _checks := 0
var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_state = root.get_node("GameState")
	_state.save_directory = ""
	_state.record_path = "user://test_kernel_routes_%d.cfg" % OS.get_process_id()
	if not _check(change_scene_to_file(SCENE) == OK, "Kernel Panic carga la mesa"):
		_finish()
		return
	await scene_changed
	_layout = current_scene.get_node_or_null("Table/KernelLayout")
	_balls = current_scene.get_node("Table/Balls")
	if not _check(_layout != null, "la mesa instancia los carriles y blancos"):
		_finish()
		return
	await _cross_rollover("Boot", Vector2(336, 418), 535)
	await _cross_rollover("BusLeft", Vector2(66, 528), 733)
	await _cross_rollover("BusRight", Vector2(606, 528), 733)
	await _hit_standup("StandupLeft", 1.0)
	await _hit_standup("StandupRight", -1.0)
	_finish()


func _cross_rollover(node_name: String, at: Vector2, exit_y: float) -> void:
	var switch := _layout.get_node(node_name) as Area2D
	var before: int = _state.score
	var passing := _spawn(at, Vector2(0, 490))
	for step in 144:
		await physics_frame
		if not is_instance_valid(passing) or passing.position.y >= exit_y:
			break
	var passed := is_instance_valid(passing) and passing.position.y >= exit_y
	var earned: int = _state.score - before
	_check(passed and earned == switch.get("points"), "%s puntúa y conduce la bola a una salida" % switch.get("caption"))
	if is_instance_valid(passing):
		passing.queue_free()
	await process_frame


func _hit_standup(node_name: String, expected_side: float) -> void:
	var target := _layout.get_node(node_name) as Node2D
	var before: int = _state.score
	var shot := _spawn(target.position + Vector2(0, 62), Vector2(0, -950))
	for step in 28:
		await physics_frame
	var correct_kick := shot.linear_velocity.x * expected_side > 150.0 and shot.linear_velocity.y > 0.0
	_check(correct_kick and _state.score - before == target.get("points"),
		"%s puntúa al impacto y devuelve la bola hacia el centro" % node_name)
	shot.queue_free()
	await process_frame


func _spawn(at: Vector2, velocity: Vector2) -> RigidBody2D:
	var ball := Ball.new()
	ball.position = at
	ball.linear_velocity = velocity
	_balls.add_child(ball)
	return ball


func _check(ok: bool, description: String) -> bool:
	_checks += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", description])
	if not ok:
		_failures += 1
	return ok


func _finish() -> void:
	print("Recorridos de Kernel Panic: %d controles / %d fallos" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
