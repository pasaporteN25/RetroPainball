extends SceneTree
## Guarda y reanuda una partida de Alicia, con una bola encerrada en el ataúd.

const GameSave := preload("res://scripts/util/game_save.gd")
const PATH := "res://scenes/alicia.tscn"
var _game: Node
var _checks := 0
var _errors := 0
var _scratch := "user://test_alicia_resume_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_game = root.get_node("GameState")
	_game.record_path = _scratch.path_join("records.cfg")
	_game.save_directory = _scratch
	if not _check(change_scene_to_file(PATH) == OK, "abre Alicia"):
		_finish()
		return
	await scene_changed
	await create_timer(0.85).timeout
	var table := current_scene.get_node("Table")
	var balls := table.get_node("Balls")
	var rules := table.get_node("AliceRules")
	var hole := table.get_node("Rabbithole") as Area2D
	for card in table.get_node("Cards").get_children():
		card.strike()
	rules._on_size_target_hit(0)
	var ball := balls.get_child(0) as RigidBody2D
	PhysicsServer2D.body_set_state(ball.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0, hole.global_position))
	await create_timer(0.2).timeout
	_check(rules.locked_balls == 1 and balls.get_child_count() == 2, "hay una bola encerrada y otra en el carril")
	var score: int = _game.score
	current_scene.save_run()
	var saved := GameSave.load_run("alicia", _scratch)
	_check(not saved.is_empty() and saved.table_id == "alicia" and saved.score == score, "se guarda la partida de Alicia")
	_check(saved.get("balls", []).size() == 2, "las bolas encerradas se guardan como bolas en juego")
	_check(saved.sonar_mask == 0 and saved.depth == 0, "Alicia guarda sonar_mask y depth en 0")
	_check(not saved.has("size_state") and not saved.has("cards_mask"), "el tamaño, los naipes y el gato no se guardan")
	_check(GameSave.load_run("nautilus", _scratch).is_empty() and GameSave.load_run("kernel_panic", _scratch).is_empty(), "no pisa otras mesas")
	var bad := saved.duplicate()
	bad.depth = 1500
	_check(GameSave.save_run(bad, _scratch) == ERR_INVALID_DATA, "un guardado de Alicia con profundidad se rechaza")
	if not _check(change_scene_to_file(PATH) == OK, "reabre Alicia"):
		_finish()
		return
	await scene_changed
	table = current_scene.get_node("Table")
	balls = table.get_node("Balls")
	_check(balls.get_child_count() == 2 and _game.score == score and _game.balls_left == saved.balls_left, "la restauración devuelve puntaje, turno y las dos bolas")
	await create_timer(1.2).timeout
	_check(_game.score >= score + 300 and not balls.get_child(0).freeze, "la bola restaurada en el ataúd vuelve al juego (una sola vez)")
	_check(balls.get_child_count() == 2 and not table.get_node("AliceRules").tea_party, "sigue habiendo dos bolas y sin Té Loco")
	_finish()


func _check(ok: bool, description: String) -> bool:
	_checks += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", description])
	if not ok:
		_errors += 1
	return ok


func _finish() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_scratch.path_join("alicia.save")))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_scratch.path_join("records.cfg")))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_scratch))
	print("Alicia (guardado): %d controles / %d fallos" % [_checks, _errors])
	quit(0 if _errors == 0 else 1)
