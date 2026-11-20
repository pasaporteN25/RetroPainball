extends SceneTree
## Comprueba la corriente en ambas direcciones y que una cámara ocupada pueda reanudarse.

const GameSave := preload("res://scripts/util/game_save.gd")
const PATH := "res://scenes/nautilus.tscn"
var _game: Node
var _checks := 0
var _errors := 0
var _scratch := "user://test_nautilus_shots_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]

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
	if not _check(table.get_node("Balls").get_child_count() == 1, "sirve la bola de prueba"):
		_finish()
		return
	var ball := table.get_node("Balls").get_child(0) as RigidBody2D
	_move(ball, table.to_global(Vector2(56, 380)), Vector2(0, 470))
	await create_timer(0.33).timeout
	_check(_game.score == 360 and ball.position.y > 575, "la bola atraviesa la corriente descendente y suma 360")
	_move(ball, table.to_global(Vector2(142, 917)), Vector2(-200, -1370))
	await create_timer(0.57).timeout
	_check(_game.score == 720 and ball.position.y < 435, "un tiro desde abajo atraviesa la corriente ascendente")
	_move(ball, table.to_global(Vector2(295, 1155)), Vector2(486, -1130))
	await create_timer(0.59).timeout
	var chamber := table.get_node("PressureChamber") as Area2D
	_check(ball.freeze and ball.global_position.distance_to(chamber.global_position) < 1.0, "la cámara recibe y retiene una bola lanzada físicamente")
	_check(_game.score == 720, "capturar no suma hasta que la cámara devuelve la bola")
	current_scene.save_run()
	var snapshot := GameSave.load_run("nautilus", _scratch)
	_check(snapshot.get("score") == 720 and snapshot.get("balls", []).size() == 1, "se guarda la bola que está dentro de la cámara")
	if not _check(change_scene_to_file(PATH) == OK, "reabre 20.000 Leguas"):
		_finish()
		return
	await scene_changed
	table = current_scene.get_node("Table")
	if not _check(table.get_node("Balls").get_child_count() == 1, "la restauración devuelve la bola guardada"):
		_finish()
		return
	ball = table.get_node("Balls").get_child(0) as RigidBody2D
	await create_timer(0.24).timeout
	_check(ball.freeze, "la cámara vuelve a capturar la bola restaurada")
	await create_timer(0.38).timeout
	_check(not ball.freeze and ball.linear_velocity.y < -600.0 and _game.score == 1200, "la cámara expulsa y premia una única vez")
	await create_timer(0.19).timeout
	var mission := table.get_node("DepthMission")
	_check(mission.sonar_mask == 4 and _game.score == 1450, "la expulsión de cámara llega al sonar de estribor")
	_finish()


func _finish() -> void:
	GameSave.clear_run("nautilus", _scratch)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_scratch))
	print("Recorridos Nautilus: %d controles / %d fallos" % [_checks, _errors])
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
