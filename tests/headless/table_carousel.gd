extends SceneTree
## U-04: selección, gestos, récords y navegación del carrusel.

var failures := 0
var scratch := "user://test_carousel_%d" % OS.get_process_id()

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var state := root.get_node("GameState")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(scratch))
	state.save_directory = scratch
	state.record_path = scratch.path_join("records.cfg")
	var cfg := ConfigFile.new()
	cfg.set_value("records/nautilus", "high_score", 12345)
	cfg.save(state.record_path)
	change_scene_to_file("res://scenes/table_select.tscn")
	await scene_changed
	var selector := current_scene
	_check(selector._cards.size() == 4 and selector._selected == 0, "cuatro mesas y primera seleccionada")
	selector._next.pressed.emit()
	_check(selector._selected == 1, "flecha selecciona Nautilus")
	var start := InputEventScreenTouch.new()
	start.position = Vector2(500, 600)
	start.pressed = true
	selector._input(start)
	var finish := InputEventScreenTouch.new()
	finish.position = Vector2(300, 600)
	finish.pressed = false
	selector._input(finish)
	_check(selector._selected == 2 and selector._swiped, "deslizar cambia de mesa sin jugar")
	selector._select(99)
	_check(selector._selected == 3, "la selección respeta el extremo")
	selector._select(1)
	selector._display_index = 1.0
	selector._layout_cards()
	_check(selector._nautilus.z_index > selector._kernel.z_index and selector._nautilus.scale.y > selector._kernel.scale.y, "mesa elegida al frente y más grande")
	_check(selector._selected_record() == 12345, "récord de prueba por mesa")
	selector._records.pressed.emit()
	await scene_changed
	_check(current_scene.scene_file_path == "res://scenes/records.tscn", "Récords abre su pantalla")
	current_scene.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(state.record_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch))
	quit(1 if failures else 0)

func _check(ok: bool, message: String) -> void:
	print(("OK: " if ok else "FALLÓ: ") + message)
	if not ok: failures += 1
