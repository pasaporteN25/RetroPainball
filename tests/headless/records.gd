extends SceneTree
## U-05: top 10 por mesa sin nombres, persistido, separable por clave y compatible con el formato viejo.

const Records := preload("res://scripts/util/records.gd")
var _scratch := "user://test_records_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(_scratch)
	var path := _scratch.path_join("records.cfg")
	var state := root.get_node("GameState")
	state.record_path = path
	state.save_directory = ""

	_check(Records.key("nautilus") == "nautilus" and Records.key("nautilus", "hard") == "nautilus@hard", "la clave admite variante")
	_check(Records.load_top(path, "kernel_panic").is_empty(), "sin archivo el top está vacío")
	_check(Records.rank_for([], 0) == 0 and Records.rank_for([], 10) == 1, "cero no entra; el primero es 1")

	for i in 10:
		Records.add(path, "kernel_panic", 1000 * (i + 1))
	var top := Records.load_top(path, "kernel_panic")
	_check(top.size() == 10 and top[0]["score"] == 10000 and top[9]["score"] == 1000, "queda ordenado de mayor a menor")
	_check(not top[0].has("initials"), "las entradas nuevas no llevan nombre")
	_check(Records.add(path, "kernel_panic", 500) == 0, "un puntaje menor al décimo no entra")
	_check(Records.add(path, "kernel_panic", 5500) == 6, "entra en su posición")
	top = Records.load_top(path, "kernel_panic")
	_check(top.size() == 10 and top[9]["score"] == 2000 and top[5]["score"] == 5500, "el top se recorta a 10")
	_check(Records.add(path, "kernel_panic", 5500) == 7, "un empate queda detrás del anterior")

	_check(Records.load_top(path, "nautilus").is_empty(), "cada mesa tiene su top")
	Records.add(path, "kernel_panic@hard", 77)
	_check(Records.load_top(path, "kernel_panic@hard").size() == 1 and Records.load_top(path, "kernel_panic")[9]["score"] == 3000,
		"una variante tiene su top aparte")

	# Formato viejo: entradas con iniciales (y una sin puntaje, que se descarta).
	var legacy := ConfigFile.new()
	legacy.set_value("top/legacy", "entries", [{"initials": "LUC", "score": 300}, {"initials": "ZZZ", "score": 900}, {"initials": "BAD"}])
	legacy.set_value("player", "initials", "LUC")
	legacy.save(path)
	var old := Records.load_top(path, "legacy")
	_check(old.size() == 2 and old[0]["score"] == 900 and old[1]["score"] == 300, "lee el formato viejo y lo ordena")
	_check(Records.add(path, "legacy", 500) == 2 and Records.load_top(path, "legacy")[1]["score"] == 500, "se puede sumar sobre un top viejo")
	var again := ConfigFile.new()
	again.load(path)
	_check(again.get_value("player", "initials", "") == "LUC", "no toca el resto del archivo")

	# Con GameState: el puntaje se guarda solo al terminar la partida.
	state.select_table("nautilus")
	state.start_game()
	state.add_score(4000, Vector2.ZERO)
	state.end_game()
	_check(state.last_result["rank"] == 1 and state.top_scores().size() == 1, "la partida entra al top y se guarda sola")
	_check(state.top_scores()[0]["score"] == 4000, "el top de la mesa tiene el puntaje")
	state.start_game()
	state.add_score(900, Vector2.ZERO)
	state.end_game()
	_check(state.top_scores().size() == 2 and state.last_result["rank"] == 2, "otra partida suma su puesto")
	state.start_game()
	state.end_game()
	_check(state.last_result["rank"] == 0 and state.top_scores().size() == 2, "sin puntos no entra al top")

	state.select_table("dracula")
	_check(state.top_scores().is_empty(), "Drácula no hereda el top de Nautilus")

	var dir := DirAccess.open(_scratch)
	if dir:
		for file in dir.get_files():
			dir.remove(file)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_scratch))
	print("records: %d fallas" % _failures)
	quit(1 if _failures else 0)


func _check(ok: bool, message: String) -> void:
	print(("OK: " if ok else "FALLÓ: ") + message)
	if not ok:
		_failures += 1
