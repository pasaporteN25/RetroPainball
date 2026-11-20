extends SceneTree
## G-03: una bola quieta fuera del carril se destraba; en el carril de saque se la deja esperar.

const PATH := "res://scenes/main.tscn"
var _game: Node
var _checks := 0
var _errors := 0
var _scratch := "user://test_stuck_ball_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_game = root.get_node("GameState")
	_game.record_path = _scratch.path_join("records.cfg")
	_game.save_directory = ""
	if not _check(change_scene_to_file(PATH) == OK, "abre Kernel Panic"):
		_finish()
		return
	await scene_changed
	await create_timer(0.8).timeout
	var table := current_scene.get_node("Table")
	var ball := table.get_node("Balls").get_child(0) as RigidBody2D
	Engine.time_scale = 3.0
	# Quieta en la lane: espera el saque sin que nadie la toque.
	var waiting_at: Vector2 = table.to_local(ball.global_position)
	await create_timer(5.0).timeout
	_check(table.to_local(ball.global_position).distance_to(waiting_at) < 4.0, "la bola que espera el saque en el carril no se mueve")
	# Quieta en medio de la mesa, sin gravedad: está trabada.
	var kicks := [0]
	ball.stuck.connect(func(): kicks[0] += 1)
	ball.gravity_scale = 0.0
	var spot := _free_spot(table)
	_move(ball, table.to_global(spot), Vector2.ZERO)
	await create_timer(4.6).timeout
	_check(kicks[0] >= 1, "la bola quieta avisa que está trabada")
	_check(ball.linear_velocity.length() > 300.0 or table.to_local(ball.global_position).distance_to(spot) > 60.0, "la bola trabada recibe un empujón")
	Engine.time_scale = 1.0
	_finish()


## Un punto de la mesa sin ninguna pieza cerca, para que la bola quede de verdad quieta.
func _free_spot(table: Node2D) -> Vector2:
	var probe := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 70.0
	probe.shape = circle
	probe.collision_mask = 1
	var space := table.get_world_2d().direct_space_state
	for y in range(480, 960, 30):
		for x in range(120, 560, 30):
			probe.transform = Transform2D(0, table.to_global(Vector2(x, y)))
			if space.intersect_shape(probe, 1).is_empty():
				return Vector2(x, y)
	return Vector2(336, 700)


func _finish() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_scratch))
	print("Bola trabada: %d controles / %d fallos" % [_checks, _errors])
	quit(0 if _errors == 0 else 1)


func _check(ok: bool, label: String) -> bool:
	_checks += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		_errors += 1
	return ok


func _move(ball: RigidBody2D, at: Vector2, velocity: Vector2) -> void:
	PhysicsServer2D.body_set_state(ball.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0, at))
	PhysicsServer2D.body_set_state(ball.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, velocity)
	PhysicsServer2D.body_set_state(ball.get_rid(), PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY, 0.0)
