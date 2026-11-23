extends SceneTree
## Una bola en reposo junto al buje de un flipper (contra la esquina del pasillo de retorno)
## no se puede quedar quieta: sin tocar los flippers tiene que salir de ahí, en ambas mesas.

const TABLES := {"Kernel Panic": "res://scenes/main.tscn", "20.000 Leguas": "res://scenes/nautilus.tscn", "Drácula": "res://scenes/dracula.tscn", "Alicia": "res://scenes/alicia.tscn"}
const SPOTS: Array[Vector2] = [Vector2(206, 1220), Vector2(464, 1219), Vector2(466, 1220)]
const MIN_TRAVEL := 40.0
const WAIT := 3.0
var _game: Node
var _checks := 0
var _errors := 0
var _scratch := "user://test_hub_trap_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_game = root.get_node("GameState")
	_game.record_path = _scratch.path_join("records.cfg")
	_game.save_directory = ""
	for table_name: String in TABLES:
		if not _check(change_scene_to_file(TABLES[table_name]) == OK, "abre " + table_name):
			continue
		await scene_changed
		await create_timer(0.8).timeout
		var table := current_scene.get_node("Table")
		Engine.time_scale = 3.0
		for spot in SPOTS:
			var ball := await _live_ball(table)
			if ball == null:
				_check(false, "%s: hay una bola para probar" % table_name)
				continue
			_move(ball, table.to_global(spot), Vector2.ZERO)
			await create_timer(WAIT).timeout
			# Si la bola ya cayó al drenaje, claramente salió del buje.
			var travel := 9999.0
			if is_instance_valid(ball) and not ball.is_queued_for_deletion():
				travel = table.to_local(ball.global_position).distance_to(spot)
			_check(travel > MIN_TRAVEL, "%s: la bola en %s se mueve (%.0f px)" % [table_name, spot, travel])
		Engine.time_scale = 1.0
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_scratch))
	print("Trampa del buje: %d controles / %d fallos" % [_checks, _errors])
	quit(0 if _errors == 0 else 1)


## Una bola en juego (espera el saque si hace falta; repone bolas para no terminar la partida).
func _live_ball(table: Node) -> RigidBody2D:
	_game.balls_left = _game.BALLS_PER_GAME
	for i in 60:
		for b in table.get_node("Balls").get_children():
			if not b.is_queued_for_deletion():
				return b as RigidBody2D
		await create_timer(0.1).timeout
	return null


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
