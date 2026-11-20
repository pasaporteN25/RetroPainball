extends SceneTree
## Los retornos deben alimentar a los flippers y las salidas laterales drenar.

const Ball := preload("res://scripts/table/ball.gd")
const GameSave := preload("res://scripts/util/game_save.gd")
const KERNEL := "res://scenes/main.tscn"
const NAUTILUS := "res://scenes/nautilus.tscn"

var _state: Node
var _table: Node2D
var _checks := 0
var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_state = root.get_node("GameState")
	_state.save_directory = ""
	_state.record_path = "user://test_lower_lanes_%d.cfg" % OS.get_process_id()
	for path in [KERNEL, NAUTILUS]:
		if change_scene_to_file(path) != OK:
			_check(false, "abre " + path)
			continue
		await scene_changed
		_table = current_scene.get_node("Table")
		await _test_left_and_right()
		await _test_shooter_gate()
	await _test_previous_save()
	print("Carriles: %d controles / %d fallos" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _test_left_and_right() -> void:
	var label: String = _state.table_id
	for side: String in ["Left", "Right"]:
		var lane := _table.get_node("LowerLanes/" + side + "Return") as Area2D
		var ball := _drop_above(lane)
		var before: int = _state.score
		var reached_flipper := false
		for frame in 175:
			await physics_frame
			if not is_instance_valid(ball) or ball.is_queued_for_deletion():
				break
			var at := ball.position
			if at.y >= 1200.0 and at.y < 1270.0:
				reached_flipper = (at.x >= 163 and at.x < 335) if side == "Left" else (at.x > 337 and at.x <= 509)
				if reached_flipper:
					break
		_check(reached_flipper and _state.score >= before + 50, "%s %s lleva al flipper y suma 50" % [label, side])
		if is_instance_valid(ball):
			ball.queue_free()

	for side: String in ["Left", "Right"]:
		var lane := _table.get_node("LowerLanes/" + side + "Outlane") as Area2D
		var left := side == "Left"
		var at := Vector2(127, 760) if left else Vector2(545, 760)
		if not left and label == "nautilus":
			at = Vector2(569, 830)
		var ball := _spawn_ball(at, Vector2(-220 if left else 220, 430))
		var crossed := [false]
		lane.body_entered.connect(func(body: Node2D) -> void:
			if is_instance_valid(ball) and body == ball:
				crossed[0] = true)
		for frame in 420:
			await physics_frame
			if not is_instance_valid(ball) or ball.is_queued_for_deletion():
				break
		var drained := not is_instance_valid(ball) or ball.is_queued_for_deletion()
		_check(crossed[0] and drained, "%s %s drena por el lateral" % [label, side])
		if is_instance_valid(ball):
			ball.queue_free()


func _test_shooter_gate() -> void:
	var label: String = _state.table_id
	var returning := _spawn_ball(Vector2(674, 357), Vector2(0, 320))
	for step in 25:
		await physics_frame
	_check(returning.position.x < 640.0 and returning.position.y < 430.0,
		"%s desvía hacia el tablero una bola que vuelve al lanzador" % label)
	returning.queue_free()

	var launched := _spawn_ball(Vector2(684, 475), Vector2(0, -1000))
	for step in 22:
		await physics_frame
	_check(launched.position.y < 414.0 and launched.position.x > 666.0,
		"%s deja subir la bola por la compuerta" % label)
	launched.queue_free()


func _test_previous_save() -> void:
	var directory := "user://test_lane_migration_%d" % OS.get_process_id()
	var original := Vector2(191, 1080)
	var saved := {
		"table_id": "kernel_panic", "score": 420, "balls_left": 2,
		"balls": [{"position": original, "velocity": Vector2(110, 160), "spin": 1.0, "rotation": 0.2}],
		"serve_remaining": 0.0, "save_remaining": 0.0, "save_armed": false,
		"sonar_mask": 0, "depth": 0,
	}
	_state.save_directory = directory
	if GameSave.save_run(saved, directory) != OK or change_scene_to_file(KERNEL) != OK:
		_check(false, "abre un guardado con la geometría anterior")
	else:
		await scene_changed
		var ball := current_scene.get_node("Table/Balls").get_child(0) as RigidBody2D
		_check(_state.score == 420 and _state.balls_left == 2, "la actualización conserva puntaje y bolas")
		_check(ball.position.distance_to(original) >= 23.0 and ball.position.distance_to(original) <= 155.0,
			"un guardado de la mesa anterior recupera la bola cerca, fuera del triángulo nuevo")
		GameSave.clear_run("kernel_panic", directory)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))


func _drop_above(lane: Area2D) -> RigidBody2D:
	return _spawn_ball(lane.position - Vector2(0, 73), Vector2(0, 290))


func _spawn_ball(at: Vector2, velocity: Vector2) -> RigidBody2D:
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
