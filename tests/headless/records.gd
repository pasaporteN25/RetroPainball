extends SceneTree
## U-05: top 10 por mesa con iniciales, persistido y separable por clave.

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

	_check(Records.clean_initials("a") == "AAA" and Records.clean_initials("x9yzw") == "XYZ", "las iniciales son 3 letras A-Z")
	_check(Records.key("nautilus") == "nautilus" and Records.key("nautilus", "hard") == "nautilus@hard", "la clave admite variante")
	_check(Records.load_top(path, "kernel_panic").is_empty(), "sin archivo el top está vacío")
	_check(Records.rank_for([], 0) == 0 and Records.rank_for([], 10) == 1, "cero no entra; el primero es 1")

	for i in 10:
		Records.add(path, "kernel_panic", "AB" + char(65 + i), 1000 * (i + 1))
	var top := Records.load_top(path, "kernel_panic")
	_check(top.size() == 10 and top[0]["score"] == 10000 and top[9]["score"] == 1000, "queda ordenado de mayor a menor")
	_check(top[0]["initials"] == "ABJ", "guarda las iniciales")
	_check(Records.add(path, "kernel_panic", "LOW", 500) == 0, "un puntaje menor al décimo no entra")
	_check(Records.add(path, "kernel_panic", "MID", 5500) == 6, "entra en su posición")
	top = Records.load_top(path, "kernel_panic")
	_check(top.size() == 10 and top[9]["score"] == 2000 and top[5]["initials"] == "MID", "el top se recorta a 10")
	_check(Records.add(path, "kernel_panic", "TIE", 5500) == 7, "un empate queda detrás del anterior")

	_check(Records.load_top(path, "nautilus").is_empty(), "cada mesa tiene su top")
	Records.add(path, "kernel_panic@hard", "HRD", 77)
	_check(Records.load_top(path, "kernel_panic@hard").size() == 1 and Records.load_top(path, "kernel_panic")[9]["score"] == 3000,
		"una variante tiene su top aparte")

	# Con GameState: fin de partida, iniciales pendientes y persistencia.
	state.select_table("nautilus")
	state.start_game()
	state.add_score(4000, Vector2.ZERO)
	state.end_game()
	_check(state.pending_record and state.last_result["rank"] == 1, "la partida entra al top y espera iniciales")
	state.pending_initials = "luc"
	_check(state.commit_pending_record() == 1 and not state.pending_record, "confirmar guarda la posición")
	_check(state.top_scores()[0]["initials"] == "LUC" and state.top_scores()[0]["score"] == 4000, "el top de la mesa tiene la entrada")
	_check(Records.load_last_initials(path) == "LUC", "recuerda las últimas iniciales")
	_check(state.commit_pending_record() == 0, "no guarda dos veces")

	state.start_game()
	state.add_score(900, Vector2.ZERO)
	state.end_game()
	state.start_game()
	_check(state.top_scores().size() == 2, "empezar otra partida guarda con las iniciales propuestas")
	state.end_game()
	_check(not state.pending_record and state.last_result["rank"] == 0, "sin puntos no entra al top")

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
