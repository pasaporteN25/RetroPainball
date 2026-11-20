extends SceneTree
## Comprueba el guardado y la restauración usando ambas escenas y directorios temporales.

const GameSave := preload("res://scripts/util/game_save.gd")
const NAUTILUS_SCENE := "res://scenes/nautilus.tscn"
const KERNEL_SCENE := "res://scenes/main.tscn"
const SELECT_SCENE := "res://scenes/table_select.tscn"
const NAUTILUS := "nautilus"
const KERNEL := "kernel_panic"

var _state: Node
var _directory := "user://test_resume_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
var _checks := 0
var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_state = root.get_node("GameState")
	_state.save_directory = _directory
	_state.record_path = _directory.path_join("records.cfg")
	if await _prepare_nautilus():
		var nautilus_save := GameSave.load_run(NAUTILUS, _directory)
		await _test_isolation(nautilus_save)
		if await _open_scene(NAUTILUS_SCENE):
			_test_restore(nautilus_save)
			await _test_finish_and_restart()
	_finish()


func _prepare_nautilus() -> bool:
	if not await _open_scene(NAUTILUS_SCENE):
		return false
	await create_timer(0.85).timeout
	var table := current_scene.get_node("Table")
	var balls := table.get_node("Balls")
	if not _check(balls.get_child_count() == 1, "la partida nueva sirve una bola"):
		return false
	table.get_node("Plunger").launched.emit(1.0)
	_state.lose_ball()
	var mission := table.get_node("DepthMission")
	for index in 3:
		mission.on_sonar(index, Vector2(320, 500))
	mission.on_kraken(Vector2(320, 500))
	mission.on_sonar(1, Vector2(320, 500))
	if not _check(balls.get_child_count() == 3, "la partida tiene multibola antes de guardar"):
		return false
	for i in 3:
		var ball := balls.get_child(i) as RigidBody2D
		var location: Vector2 = table.to_global(Vector2(200 + i * 150, 320))
		PhysicsServer2D.body_set_state(ball.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM,
			Transform2D(0.45 + i * 0.20, location))
		PhysicsServer2D.body_set_state(ball.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY,
			Vector2(260 + i * 40, -320))
		PhysicsServer2D.body_set_state(ball.get_rid(), PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY,
			2.0 + i)
	await create_timer(0.05).timeout
	var hud := current_scene.get_node("HUD")
	hud.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	var snapshot := GameSave.load_run(NAUTILUS, _directory)
	_check(paused, "pasar a segundo plano pausa la mesa")
	_check(snapshot.get("score") == 6000 and snapshot.get("balls_left") == 2,
		"pasar a segundo plano guarda el puntaje y las bolas restantes")
	_check(snapshot.get("sonar_mask") == 2 and snapshot.get("depth") == 1500,
		"se guardan el sonar activo y la profundidad")
	_check(snapshot.get("save_remaining", 0.0) > 7.0 and snapshot.get("balls", []).size() == 3,
		"se guardan el salvavidas activo y las tres bolas en juego")
	hud._open_tables()
	await scene_changed
	return _check(current_scene.scene_file_path == SELECT_SCENE and not paused,
		"Mesas vuelve al selector y permite abrir otra partida")


func _test_isolation(nautilus_save: Dictionary) -> void:
	if not await _open_scene(KERNEL_SCENE):
		return
	_check(_state.score == 0 and _state.balls_left == 3, "Kernel Panic inicia una partida independiente")
	await create_timer(0.85).timeout
	_check(current_scene.ball_count() == 1, "el saque de Kernel Panic ocurre antes de probar el guardado periódico")
	_state.add_score(345, Vector2(320, 500))
	# El juego corre mientras se espera que el guardado periódico haga visible el puntaje.
	var kernel_save: Dictionary
	for attempt in 25:
		await create_timer(0.2).timeout
		kernel_save = GameSave.load_run(KERNEL, _directory)
		if kernel_save.get("score") == 345:
			break
	_check(kernel_save.get("score") == 345, "el guardado periódico registra el puntaje sin pausar")
	_check(GameSave.load_run(NAUTILUS, _directory) == nautilus_save,
		"la partida de Kernel Panic conserva el guardado del Nautilus")
	var hud := current_scene.get_node("HUD")
	_state.add_score(155, Vector2(320, 500))
	hud._open_tables()
	await scene_changed
	_check(GameSave.load_run(KERNEL, _directory).get("score") == 500,
		"volver al selector guarda el último puntaje")


func _test_restore(snapshot: Dictionary) -> void:
	var table := current_scene.get_node("Table")
	var mission := table.get_node("DepthMission")
	var balls := table.get_node("Balls")
	var saved_balls: Array = snapshot.get("balls", [])
	_check(_state.playing and _state.score == 6000 and _state.balls_left == 2,
		"volver a abrir 20.000 Leguas restaura el puntaje y las bolas restantes")
	_check(mission.sonar_mask == 2 and mission.depth == 1500, "se retoma el progreso de la misión")
	var ball_save: float = snapshot.get("save_remaining", 0.0)
	_check(absf(current_scene._ball_save_left - ball_save) < 0.1 and ball_save > 0.0,
		"se restaura el tiempo del salvavidas")
	if not _check(balls.get_child_count() == 3 and saved_balls.size() == 3, "se reanuda la multibola"):
		return
	var matches := true
	for i in saved_balls.size():
		var ball := balls.get_child(i) as RigidBody2D
		var saved: Dictionary = saved_balls[i]
		matches = matches and ball.position.distance_to(saved.position) < 15.0
		matches = matches and ball.linear_velocity.distance_to(saved.velocity) < 100.0
		matches = matches and absf(ball.angular_velocity - saved.spin) < 0.3
		matches = matches and absf(angle_difference(ball.rotation, saved.rotation)) < 0.3
	_check(matches, "las bolas retoman la posición, la velocidad y el giro guardados")


func _test_finish_and_restart() -> void:
	_state.end_game()
	_check(GameSave.load_run(NAUTILUS, _directory).is_empty(),
		"una partida terminada ya no se puede continuar")
	_check(GameSave.load_run(KERNEL, _directory).get("score") == 500,
		"terminar Nautilus conserva la partida de Kernel Panic")
	_state.start_game()
	await create_timer(0.26).timeout
	current_scene.save_run()
	var snapshot := GameSave.load_run(NAUTILUS, _directory)
	var serve_remaining: float = snapshot.get("serve_remaining", 0.0)
	_check(snapshot.get("score") == 0 and snapshot.get("sonar_mask") == 0 and snapshot.get("depth") == 0,
		"reiniciar guarda una partida limpia")
	_check(snapshot.get("balls", []).is_empty() and serve_remaining > 0.0 and serve_remaining < 0.65,
		"se guarda el tiempo pendiente antes de servir")
	if not await _open_scene(NAUTILUS_SCENE):
		return
	var balls := current_scene.get_node("Table/Balls")
	_check(balls.get_child_count() == 0, "reanudar antes de servir no crea una bola de más")
	await create_timer(serve_remaining + 0.14).timeout
	_check(balls.get_child_count() == 1, "se sirve una bola al terminar la espera restaurada")


func _open_scene(path: String) -> bool:
	if not _check(change_scene_to_file(path) == OK, "se abre " + path.get_file()):
		return false
	await scene_changed
	return true


func _check(ok: bool, description: String) -> bool:
	_checks += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", description])
	if not ok:
		_failures += 1
	return ok


func _finish() -> void:
	GameSave.clear_run(NAUTILUS, _directory)
	GameSave.clear_run(KERNEL, _directory)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_state.record_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_directory))
	print("Guardado: %d controles / %d fallos" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
