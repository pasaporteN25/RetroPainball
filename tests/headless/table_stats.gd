extends SceneTree
## U-09: estadísticas por mesa (partidas, mejor bola, jackpots), persistidas y separadas por mesa.

const TableStats := preload("res://scripts/util/table_stats.gd")
const Records := preload("res://scripts/util/records.gd")
var _scratch := "user://test_table_stats_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(_scratch)
	var path := _scratch.path_join("records.cfg")
	var state := root.get_node("GameState")
	state.record_path = path
	state.save_directory = ""

	_check(TableStats.load_stats(path, "nautilus") == {"games": 0, "best_ball": 0, "jackpots": 0}, "sin archivo todo está en cero")

	state.select_table("nautilus")
	state.start_game()
	state.add_score(1000, Vector2.ZERO)
	state.register_jackpot()
	state.lose_ball()
	state.add_score(4000, Vector2.ZERO)
	state.register_jackpot()
	state.register_jackpot()
	state.lose_ball()
	state.add_score(500, Vector2.ZERO)
	state.lose_ball()
	var stats: Dictionary = state.table_stats("nautilus")
	_check(stats["games"] == 1 and stats["best_ball"] == 4000 and stats["jackpots"] == 3, "una partida suma partida, mejor bola y jackpots")

	state.start_game()
	state.add_score(200, Vector2.ZERO)
	state.end_game()
	stats = state.table_stats("nautilus")
	_check(stats["games"] == 2 and stats["best_ball"] == 4000 and stats["jackpots"] == 3, "la segunda partida no baja el máximo ni repite jackpots")

	_check(state.table_stats("dracula")["games"] == 0, "cada mesa tiene sus estadísticas")
	state.commit_pending_record()
	_check(Records.load_top(path, "nautilus").size() >= 1 and state.table_stats("nautilus")["games"] == 2, "las estadísticas conviven con el top de récords")

	var cfg := ConfigFile.new()
	cfg.load(path)
	cfg.set_value("stats/alicia", "games", "basura")
	cfg.set_value("stats/alicia", "best_ball", -5)
	cfg.save(path)
	_check(state.table_stats("alicia") == {"games": 0, "best_ball": 0, "jackpots": 0}, "los datos inválidos se ignoran")

	root.content_scale_size = Vector2i(720, 1280)
	var screen = load("res://scenes/records.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	var text: String = screen.stats_text("nautilus")
	_check(text.contains("Partidas 2") and text.contains("4.000") and text.contains("Jackpots 3"), "la pantalla de récords muestra las estadísticas")
	screen.show_table("nautilus")
	_check(screen._stat_values[0].text == "2" and screen._stat_values[1].text == "4.000" and screen._stat_values[2].text == "3", "el panel muestra las tres estadísticas de Nautilus")
	screen.show_table("dracula")
	_check(screen._stat_values[0].text == "0" and screen._stat_values[1].text == "0" and screen._stat_values[2].text == "0", "al cambiar de pestaña se actualiza el panel")
	await process_frame
	await process_frame
	var visible := root.get_visible_rect()
	_check(visible.size == Vector2(720, 1280) and visible.encloses(screen._panel.get_global_rect()), "el panel de récords entra en un viewport vertical 9:16")
	var back: Button = screen._back
	_check(back.has_focus() and back.get_node(back.focus_neighbor_top) == screen._tabs[2], "Volver conecta con la pestaña activa")
	screen.queue_free()

	var dir := DirAccess.open(_scratch)
	if dir:
		for file in dir.get_files():
			dir.remove(file)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_scratch))
	print("table_stats: %d fallas" % _failures)
	quit(1 if _failures else 0)


func _check(ok: bool, message: String) -> void:
	print(("OK: " if ok else "FALLÓ: ") + message)
	if not ok:
		_failures += 1
