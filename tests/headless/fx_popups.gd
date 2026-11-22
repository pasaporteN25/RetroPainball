extends SceneTree

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, detail: String) -> void:
	if not condition:
		failures += 1
		printerr("FALLÓ: " + detail)

func _run() -> void:
	var state := root.get_node("GameState")
	var scratch := "user://test_fx_popups_%d" % OS.get_process_id()
	state.save_directory = scratch
	state.record_path = scratch + "/records.cfg"
	state.table_id = "kernel_panic"
	var small = load("res://scripts/fx/score_popup.gd").new()
	small.setup(100, Vector2(300, 300), Color.WHITE)
	root.add_child(small)
	state.table_id = "nautilus"
	var big = load("res://scripts/fx/score_popup.gd").new()
	big.setup(1000, Vector2(300, 300), Color.WHITE)
	root.add_child(big)
	check(small.color != big.color and small.plate_color != big.plate_color, "cada mesa tiene su paleta")
	check(small.font.font_names != big.font.font_names, "cada mesa tiene su familia tipográfica")
	check(big.font_size > small.font_size and big.duration > small.duration, "el puntaje alto es más grande y dura más")
	await create_timer(0.85).timeout
	check(not is_instance_valid(small) and is_instance_valid(big), "cada popup respeta su duración")
	await create_timer(0.4).timeout
	check(not is_instance_valid(big), "el popup grande se libera solo")
	print("Popups: %d fallos" % failures)
	quit(1 if failures else 0)
