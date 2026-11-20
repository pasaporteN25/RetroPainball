extends SceneTree
## Dos reglas del pinball: la cámara de presión no recaptura una bola que acaba de expulsar
## (ciclo infinito) y la bola no puede volver al carril de saque desde el arco.

const GameSave := preload("res://scripts/util/game_save.gd")
const PATH := "res://scenes/nautilus.tscn"
var _game: Node
var _checks := 0
var _errors := 0
var _scratch := "user://test_table_loops_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_game = root.get_node("GameState")
	_game.record_path = _scratch.path_join("records.cfg")
	_game.save_directory = _scratch
	if not _check(change_scene_to_file(PATH) == OK, "abre 20.000 Leguas"):
		_finish()
		return
	await scene_changed
	await create_timer(0.80).timeout
	var table := current_scene.get_node("Table")
	var ball := table.get_node("Balls").get_child(0) as RigidBody2D
	var chamber := table.get_node("PressureChamber")
	var launches := [0]
	chamber.get_node("ReleaseTimer").timeout.connect(func(): launches[0] += 1)
	_move(ball, table.to_global(Vector2(552, 700)), Vector2(0, 300))
	await create_timer(1.0).timeout
	_check(launches[0] == 1, "la cámara captura y expulsa la bola una vez")
	# La bola vuelve a caer sobre la cámara: ya no debe quedar retenida.
	_move(ball, table.to_global(Vector2(552, 700)), Vector2(0, 300))
	await create_timer(1.2).timeout
	_check(launches[0] == 1 and not ball.freeze, "una bola ya expulsada no se recaptura")
	_check(table.to_local(ball.global_position).y > 800.0, "la bola sigue bajando hacia los flippers")
	# Al bajar a la zona de los flippers la cámara vuelve a armarse.
	_move(ball, table.to_global(Vector2(300, 1050)), Vector2(0, 100))
	await create_timer(0.2).timeout
	_move(ball, table.to_global(Vector2(552, 700)), Vector2(0, 300))
	await create_timer(0.9).timeout
	_check(launches[0] == 2, "tras volver a los flippers la cámara captura de nuevo")

	# Carril de saque: ninguna bola que baja por el arco debe terminar dentro.
	for shot in [
			[Vector2(660, 310), Vector2(42, 42)],
			[Vector2(660, 310), Vector2(60, 140)],
			[Vector2(690, 330), Vector2(0, 30)],
			[Vector2(620, 250), Vector2(2300, 690)]]:
		if not is_instance_valid(ball) or ball.is_queued_for_deletion() or table.get_node("Balls").get_child_count() == 0:
			change_scene_to_file(PATH)
			await scene_changed
			await create_timer(0.80).timeout
			table = current_scene.get_node("Table")
			ball = table.get_node("Balls").get_child(0) as RigidBody2D
		_move(ball, table.to_global(shot[0]), shot[1])
		await create_timer(1.6).timeout
		var at: Vector2 = table.to_local(ball.global_position) if is_instance_valid(ball) else Vector2.ZERO
		_check(not (at.x > 664.0 and at.y > 440.0), "desde %s a %s la bola no entra al carril de saque (termina en %s)" % [shot[0], shot[1], at.round()])
	_finish()


func _finish() -> void:
	GameSave.clear_run("nautilus", _scratch)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_scratch))
	print("Bucles de mesa: %d controles / %d fallos" % [_checks, _errors])
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
