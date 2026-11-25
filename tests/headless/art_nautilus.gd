extends SceneTree
## Ejercita los estados visuales en una mesa real y verifica su limpieza.

const TitleLayout := preload("res://tests/support/table_title_layout.gd")

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var state := root.get_node("GameState")
	var test_dir := "user://test_art_nautilus_%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_dir))
	state.record_path = test_dir + "/records.cfg"
	state.save_directory = test_dir
	var scene = load("res://scenes/nautilus.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var table = scene.get_node("Table")
	var art = table.get_node("PlayfieldArt")
	var layout: Dictionary = art.get_script().get_script_constant_map()
	var wall: Node2D = table.get_node("OuterWall")
	var heading := TitleLayout.text_bounds(art._title_font, layout.TITLE, layout.TITLE_AT, art.title_size(), 11.0, 4.0)
	var subtitle := TitleLayout.text_bounds(ThemeDB.fallback_font, layout.SUBTITLE, layout.SUBTITLE_AT, layout.SUBTITLE_SIZE, 5.0)
	_check(TitleLayout.title_fits(art, wall, heading) and TitleLayout.title_fits(art, wall, subtitle),
		"el título y el subtítulo entran en pantalla vertical por dentro del arco")
	var ambient = art.get_node("Ambient")
	_check(ambient._positions.size() == 24, "pool de 24 burbujas")
	var sonar = table.get_node("Sonars/Port")
	sonar.set_lit(true)
	art.set_mission_status(7, 1500, true)
	art.flash_jackpot()
	var kraken = table.get_node("Kraken")
	kraken.set_armed(true)
	kraken._flash = 1.0
	var chamber = table.get_node("PressureChamber")
	chamber._flash = 1.0
	chamber.set_process(true)
	var current = table.get_node("CurrentRoute")
	current._pulse = 1.0
	for node in [art, ambient, sonar, kraken, chamber, current]:
		node.queue_redraw()
	await process_frame
	await process_frame
	_check(sonar._ping > 0.0 and art._display_depth > 0.0, "ping y profundidad animados")
	sonar.set_lit(false)
	var reference = weakref(ambient)
	scene.queue_free()
	await process_frame
	_check(reference.get_ref() == null, "efectos liberados junto a la mesa")
	for file in DirAccess.get_files_at(test_dir):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_dir.path_join(file)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_dir))
	print("Arte Nautilus: %d fallos" % failures)
	quit(1 if failures else 0)

func _check(ok: bool, description: String) -> void:
	print("[%s] %s" % ["PASS" if ok else "FAIL", description])
	if not ok:
		failures += 1
