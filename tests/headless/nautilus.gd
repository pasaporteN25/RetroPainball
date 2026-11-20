extends SceneTree
## Integración de la segunda mesa: tránsito por sensores reales, golpe físico,
## multibola, reinicio y récords por mesa.

const TEST_RECORD := "user://test_nautilus_records.cfg"

var _failures := 0
var _checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state: Node = root.get_node("GameState")
	state.record_path = TEST_RECORD
	state.save_directory = ""
	var records := ConfigFile.new()
	records.set_value("records", "high_score", 888)
	records.save(TEST_RECORD)
	change_scene_to_file("res://scenes/nautilus.tscn")
	await scene_changed
	var table := current_scene.get_node("Table")
	var mission := table.get_node("DepthMission")
	var targets := table.get_node("Sonars").get_children()
	var balls := table.get_node("Balls")
	_check(state.table_id == "nautilus" and state.high_score == 0, "Nautilus tiene su propio récord")
	await _wait(0.86)
	_check(balls.get_child_count() == 1 and state.ball_in_lane, "Nautilus sirve una bola en el carril")
	if balls.get_child_count() != 1:
		_finish()
		return
	var ball := balls.get_child(0) as RigidBody2D
	for target in targets:
		_move(ball, target.global_position)
		await _wait(0.07)
	_check(state.score == 750 and mission.is_kraken_active(), "los tres sensores físicos activan el kraken")

	_move(ball, targets[0].global_position)
	await _wait(0.07)
	_check(state.score == 750, "un sonar marcado no vuelve a sumar")
	var kraken := table.get_node("Kraken") as Node2D
	_move(ball, kraken.global_position + Vector2(0, -110), Vector2(0, 1000))
	await _wait(0.14)
	_check(mission.depth == 1500 and mission.sonar_mask == 0, "el jackpot desciende 1.500 m y rearma los sonares")
	_check(state.score == 5750 and balls.get_child_count() == 3, "el kraken suma el jackpot y larga dos bolas")
	if balls.get_child_count() != 3:
		_finish()
		return

	for i in [1, 2]:
		_move(balls.get_child(i), table.to_global(Vector2(240 + i * 90, 1500)))
	await _wait(0.10)
	_check(state.balls_left == 3 and balls.get_child_count() == 1, "drenar dos bolas de multibola no gasta turno")
	_move(ball, targets[0].global_position)
	await _wait(0.08)
	_move(ball, table.to_global(Vector2(336, 1500)))
	await _wait(0.12)
	_check(state.balls_left == 2 and mission.depth == 1500 and mission.sonar_mask == 1, "el progreso sigue después del drenaje")

	state.end_game()
	var nautilus_record: int = state.high_score
	mission.on_sonar(1, Vector2.ZERO)
	mission.on_kraken(Vector2.ZERO)
	_check(mission.depth == 1500 and mission.sonar_mask == 1, "una partida terminada no modifica la misión")
	state.start_game()
	state.start_game()
	await _wait(0.80)
	_check(mission.depth == 0 and mission.sonar_mask == 0 and balls.get_child_count() == 1,
		"reiniciar resetea la misión y sirve una sola bola")

	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	_check(state.high_score == 888, "la partida Nautilus conserva el récord anterior de Kernel Panic")
	change_scene_to_file("res://scenes/nautilus.tscn")
	await scene_changed
	_check(state.high_score == nautilus_record and nautilus_record >= 5750, "Nautilus recupera su récord al volver")
	_finish()


func _check(ok: bool, description: String) -> void:
	_checks += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", description])
	if not ok:
		_failures += 1


func _finish() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_RECORD))
	print("Nautilus: %d controles / %d fallos" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _move(ball: RigidBody2D, at: Vector2, velocity := Vector2.ZERO) -> void:
	PhysicsServer2D.body_set_state(ball.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0, at))
	PhysicsServer2D.body_set_state(ball.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, velocity)


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout
