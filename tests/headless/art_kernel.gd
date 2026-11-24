extends SceneTree

const TitleLayout := preload("res://tests/support/table_title_layout.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var state := root.get_node("GameState")
	var path := "user://test_art_kernel_%d" % OS.get_process_id()
	state.record_path = path + "/records.cfg"
	state.save_directory = path
	state.select_table("kernel_panic")
	state.start_game()
	var art = load("res://scripts/table/playfield_art.gd").new()
	root.add_child(art)
	var scene := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	var wall := scene.get_node("Table/OuterWall") as Node2D
	var layout: Dictionary = art.get_script().get_script_constant_map()
	var titles_fit: bool = layout.TITLE_LINES.size() == 2
	for line in layout.TITLE_LINES:
		var bounds := TitleLayout.text_bounds(art._title_font, line[0], line[1], layout.TITLE_SIZE, 10.0, 5.0)
		var fits := TitleLayout.title_fits(art, wall, bounds)
		print("[%s] %s entra en pantalla vertical por dentro del arco" % ["PASS" if fits else "FAIL", line[0]])
		titles_fit = titles_fit and fits
	scene.free()
	var bumper = load("res://scripts/table/bumper.gd").new()
	root.add_child(bumper)
	await process_frame
	state.raise_multiplier(false)
	await process_frame
	assert(art._mood == 1)
	bumper._flash = 1.0
	bumper.queue_redraw()
	state.bonus_awarded.emit(100, 2, 200)
	state.lose_ball()
	assert(art._mood == -1)
	assert(art.get_child_count() == 5)
	await create_timer(1.3).timeout
	assert(art.get_child_count() == 4)
	state.select_table("nautilus")
	bumper.queue_redraw()
	await process_frame
	art.queue_free()
	bumper.queue_free()
	await process_frame
	print("art_kernel OK" if titles_fit else "art_kernel: falló el chequeo del título")
	quit(0 if titles_fit else 1)
