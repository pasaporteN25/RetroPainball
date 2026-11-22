extends SceneTree
## Una bola que sale de la mesa (por ejemplo atravesando una pared) se da por perdida y sale otra.

var _checks := 0
var _errors := 0
var _scratch := "user://test_escaped_ball_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node("GameState")
	game.record_path = _scratch.path_join("records.cfg")
	game.save_directory = ""
	for path: String in ["res://scenes/main.tscn", "res://scenes/nautilus.tscn"]:
		change_scene_to_file(path)
		await scene_changed
		await create_timer(0.8).timeout
		var table := current_scene.get_node("Table")
		var ball := table.get_node("Balls").get_child(0) as RigidBody2D
		var before: int = game.balls_left
		for outside in [Vector2(-130, 291), Vector2(850, 400), Vector2(300, -140), Vector2(300, 1990)]:
			ball = table.get_node("Balls").get_child(0) as RigidBody2D
			var lives: int = game.balls_left
			_move(ball, table.to_global(outside))
			await create_timer(0.3).timeout
			_check(game.balls_left == lives - 1 and (not is_instance_valid(ball) or ball.is_queued_for_deletion()), "%s: la bola en %s se da por perdida" % [path.get_file(), outside])
			await create_timer(1.0).timeout
			if game.balls_left > 0:
				_check(table.get_node("Balls").get_child_count() == 1, "%s: sale una bola nueva" % path.get_file())
			if not game.playing:
				game.start_game()
				await create_timer(1.0).timeout
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_scratch))
	print("Bola escapada: %d controles / %d fallos" % [_checks, _errors])
	quit(0 if _errors == 0 else 1)


func _check(ok: bool, label: String) -> bool:
	_checks += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		_errors += 1
	return ok


func _move(ball: RigidBody2D, at: Vector2) -> void:
	PhysicsServer2D.body_set_state(ball.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0, at))
	PhysicsServer2D.body_set_state(ball.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)
