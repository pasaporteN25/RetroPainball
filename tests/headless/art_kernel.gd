extends SceneTree

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
	print("art_kernel OK")
	quit()
