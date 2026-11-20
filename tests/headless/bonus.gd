extends SceneTree
## G-07: el bonus se acumula, se multiplica con las misiones y se cobra al perder la bola.

const GameSave := preload("res://scripts/util/game_save.gd")
var _game: Node
var _checks := 0
var _errors := 0
var _scratch := "user://test_bonus_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_game = root.get_node("GameState")
	_game.record_path = _scratch.path_join("records.cfg")
	_game.save_directory = _scratch
	_game.select_table("nautilus")
	_game.start_game()
	_game.add_score(1000, Vector2.ZERO)
	_game.add_score(500, Vector2.ZERO)
	_check(_game.bonus == 150, "cada puntaje suma el 10 % al bonus")
	_check(_game.bonus_multiplier == 1, "el multiplicador empieza en x1")
	_game.raise_multiplier()
	_game.raise_multiplier()
	_check(_game.bonus_multiplier == 3, "las misiones suben el multiplicador")
	for i in 10:
		_game.raise_multiplier()
	_check(_game.bonus_multiplier == _game.MAX_MULTIPLIER, "el multiplicador tiene tope")
	_game.resume_game(1500, 3, 150, 3)
	_check(_game.bonus == 150 and _game.bonus_multiplier == 3, "reanudar restaura bonus y multiplicador")
	var awards := []
	_game.bonus_awarded.connect(func(base, mult, total): awards.append([base, mult, total]))
	var alive: bool = _game.lose_ball()
	_check(alive and _game.score == 1500 + 450 and awards == [[150, 3, 450]], "perder la bola cobra bonus x multiplicador")
	_check(_game.bonus == 0 and _game.bonus_multiplier == 1, "tras cobrar el bonus se reinicia")
	_game.lose_ball()
	_check(_game.last_bonus_award == 0 and awards.size() == 1, "sin bonus no hay cobro")
	_game.add_score(2000, Vector2.ZERO)
	var before: int = _game.score
	_game.lose_ball()
	_check(_game.score == before + 200 and not _game.playing, "la última bola también cobra el bonus antes de terminar")

	# Guardado: conserva el bonus y sigue aceptando partidas viejas sin esas claves.
	var state := {
		"table_id": "nautilus", "score": 900, "balls_left": 2, "balls": [], "serve_remaining": 0.0,
		"save_remaining": 0.0, "save_armed": false, "sonar_mask": 0, "depth": 0,
	}
	_check(GameSave.save_run(state, _scratch) == OK and GameSave.load_run("nautilus", _scratch) == state, "una partida sin bonus (versión vieja) sigue siendo válida")
	state["bonus"] = 340
	state["bonus_multiplier"] = 4
	_check(GameSave.save_run(state, _scratch) == OK and GameSave.load_run("nautilus", _scratch) == state, "el guardado conserva bonus y multiplicador")
	state["bonus_multiplier"] = 9
	_check(GameSave.save_run(state, _scratch) == ERR_INVALID_DATA, "un multiplicador fuera de rango se rechaza")
	state["bonus_multiplier"] = 2
	state["serve_remaining"] = 1.5
	_check(GameSave.save_run(state, _scratch) == OK, "se puede guardar durante la espera larga posterior a un bonus")
	_finish()


func _finish() -> void:
	GameSave.clear_run("nautilus", _scratch)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_scratch))
	print("Bonus: %d controles / %d fallos" % [_checks, _errors])
	quit(0 if _errors == 0 else 1)


func _check(ok: bool, label: String) -> bool:
	_checks += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		_errors += 1
	return ok
