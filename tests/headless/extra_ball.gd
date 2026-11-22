extends SceneTree
## G-12: bola extra (hito del bonus) y persistencia del kickback y las bolas extra al reanudar.

const GameSave := preload("res://scripts/util/game_save.gd")
const KERNEL := "res://scenes/main.tscn"

var _state: Node
var _checks := 0
var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_state = root.get_node("GameState")
	_state.save_directory = ""
	_state.record_path = "user://test_extra_ball_%d.cfg" % OS.get_process_id()
	_test_rules()
	_test_save_format()
	await _test_resume()
	print("Bola extra: %d controles / %d fallos" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _test_rules() -> void:
	_state.start_game()
	_check(_state.extra_balls == 0 and _state.kickback_ready, "una partida nueva no tiene bolas extra y el kickback está listo")
	# Hito del bonus: llegar al multiplicador máximo.
	for i in _state.MAX_MULTIPLIER - 2:
		_state.raise_multiplier()
	_check(_state.extra_balls == 0, "antes del multiplicador máximo no hay bola extra")
	_state.raise_multiplier()
	_check(_state.bonus_multiplier == _state.MAX_MULTIPLIER and _state.extra_balls == 1,
		"el multiplicador máximo otorga una bola extra")
	_check(_state.award_extra_ball() and _state.extra_balls == 2, "se pueden acumular hasta el máximo pendiente")
	_check(not _state.award_extra_ball() and _state.extra_balls == 2, "no pasa del máximo pendiente")
	_state.extra_balls = 1
	var balls: int = _state.balls_left
	_check(_state.lose_ball() and _state.balls_left == balls and _state.extra_balls == 0 and _state.last_ball_replayed,
		"perder la bola con una extra la repite sin gastar bolas")
	_check(_state.lose_ball() and _state.balls_left == balls - 1 and not _state.last_ball_replayed,
		"sin bola extra, perder la bola gasta una")
	# Una sola por partida por el hito: volver a llegar al máximo no regala otra.
	for i in _state.MAX_MULTIPLIER:
		_state.raise_multiplier(false)
	_check(_state.extra_balls == 0, "el hito del bonus da una sola bola extra por partida")
	_state.balls_left = 1
	_state.extra_balls = 1
	_check(_state.lose_ball() and _state.balls_left == 1, "la bola extra salva también la última bola")
	_check(not _state.lose_ball() and not _state.playing, "sin extra, perder la última bola termina la partida")
	_state.start_game()
	_check(_state.extra_balls == 0 and _state.extra_awarded == 0, "una partida nueva reinicia las bolas extra")
	_state.leave_game()


func _test_save_format() -> void:
	var directory := "user://test_extra_ball_save_%d" % OS.get_process_id()
	var base := {
		"table_id": "kernel_panic", "score": 10, "balls_left": 2, "balls": [],
		"serve_remaining": 0.0, "save_remaining": 0.0, "save_armed": false,
		"sonar_mask": 0, "depth": 0,
	}
	var with_bonus := base.duplicate()
	with_bonus.merge({"bonus": 100, "bonus_multiplier": 2})
	var full := with_bonus.duplicate()
	full.merge({"extra_balls": 1, "extra_awarded": 1, "kickback_ready": false})
	_check(GameSave.save_run(base, directory) == OK, "un guardado sin bonus sigue siendo válido")
	_check(GameSave.save_run(with_bonus, directory) == OK, "un guardado con bonus pero sin extras sigue siendo válido")
	_check(GameSave.save_run(full, directory) == OK and GameSave.load_run("kernel_panic", directory) == full,
		"un guardado con bolas extra y kickback ida y vuelta")
	var bad := full.duplicate()
	bad.extra_balls = 9
	_check(GameSave.save_run(bad, directory) != OK, "rechaza bolas extra fuera de rango")
	bad = full.duplicate()
	bad.kickback_ready = 1
	_check(GameSave.save_run(bad, directory) != OK, "rechaza un kickback que no es booleano")
	bad = base.duplicate()
	bad.merge({"extra_balls": 1, "extra_awarded": 1, "kickback_ready": true})
	_check(GameSave.save_run(bad, directory) != OK, "rechaza extras sin las claves del bonus")
	GameSave.clear_run("kernel_panic", directory)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))


func _test_resume() -> void:
	var directory := "user://test_extra_ball_resume_%d" % OS.get_process_id()
	_state.save_directory = directory
	change_scene_to_file(KERNEL)
	await scene_changed
	await create_timer(0.5).timeout
	_state.extra_balls = 1
	_state.extra_awarded = 1
	_state.kickback_ready = false
	current_scene.save_run()
	var saved: Dictionary = GameSave.load_run("kernel_panic", directory)
	_check(saved.get("extra_balls") == 1 and saved.get("kickback_ready") == false, "la partida guarda bolas extra y kickback")
	change_scene_to_file(KERNEL)
	await scene_changed
	await create_timer(0.3).timeout
	_check(_state.extra_balls == 1 and _state.extra_awarded == 1 and not _state.kickback_ready,
		"al reanudar se recuperan las bolas extra y el kickback gastado")
	_state.leave_game()
	GameSave.clear_run("kernel_panic", directory)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
	_state.save_directory = ""


func _check(ok: bool, description: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", description])
