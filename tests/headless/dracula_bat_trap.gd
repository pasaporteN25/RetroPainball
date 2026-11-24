extends SceneTree
## Drácula: una bola no puede quedarse apoyada sobre un murciélago del banco (el tope plano la
## sostenía y el detector la daba por trabada). Se la suelta quieta sobre cada murciélago, en
## varios puntos de su cara superior, y tiene que irse sola.

const PATH := "res://scenes/dracula.tscn"
const BATS := ["BatLeft", "BatMid", "BatRight"]
## Desplazamientos horizontales sobre el murciélago (el rectángulo mide 56 de ancho).
const OFFSETS := [-26.0, -14.0, 0.0, 14.0, 26.0]
const MIN_TRAVEL := 40.0
const WAIT := 3.0
var _game: Node
var _checks := 0
var _errors := 0
var _scratch := "user://test_dracula_bat_trap_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_game = root.get_node("GameState")
	_game.record_path = _scratch.path_join("records.cfg")
	_game.save_directory = ""
	if not _check(change_scene_to_file(PATH) == OK, "abre Drácula"):
		_finish()
		return
	await scene_changed
	await create_timer(0.8).timeout
	var table := current_scene.get_node("Table")
	Engine.time_scale = 3.0
	for bat_name: String in BATS:
		var bat := table.get_node("Bats/" + bat_name) as Node2D
		for dx: float in OFFSETS:
			var ball := await _live_ball(table)
			if ball == null:
				_check(false, "hay una bola para probar")
				continue
			var radius: float = (ball.get_child(0) as CollisionShape2D).shape.radius
			# Justo apoyada sobre el punto más alto del murciélago en esa columna.
			var top := _top_y(table, bat.global_position.x + dx, bat.global_position.y)
			var spot := Vector2(bat.global_position.x + dx, top - radius - 0.5)
			_move(ball, spot, Vector2.ZERO)
			await create_timer(WAIT).timeout
			var travel := 9999.0
			if is_instance_valid(ball) and not ball.is_queued_for_deletion():
				travel = ball.global_position.distance_to(spot)
			_check(travel > MIN_TRAVEL, "%s %+.0f: la bola apoyada se va (%.0f px)" % [bat_name, dx, travel])
	Engine.time_scale = 1.0
	_finish()


## Altura (y global) de la cara superior del murciélago en esa columna, medida con un rayo.
func _top_y(table: Node2D, x: float, near_y: float) -> float:
	var query := PhysicsRayQueryParameters2D.create(Vector2(x, near_y - 60.0), Vector2(x, near_y + 60.0))
	query.collision_mask = 1
	var hit := table.get_world_2d().direct_space_state.intersect_ray(query)
	return hit.position.y if not hit.is_empty() else near_y - 12.0


func _live_ball(table: Node) -> RigidBody2D:
	_game.balls_left = _game.BALLS_PER_GAME
	for i in 60:
		for b in table.get_node("Balls").get_children():
			if not b.is_queued_for_deletion():
				return b as RigidBody2D
		await create_timer(0.1).timeout
	return null


func _finish() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_scratch))
	print("Murciélagos de Drácula: %d controles / %d fallos" % [_checks, _errors])
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
