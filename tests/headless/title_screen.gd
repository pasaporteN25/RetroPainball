extends SceneTree
## U-03: la pantalla de título es la escena inicial; tocar abre el selector; Opciones y Récords funcionan.

var failures := 0
var scratch := "user://test_title_%d" % OS.get_process_id()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	var s := root.get_node("Settings")
	state.save_directory = scratch
	state.record_path = scratch.path_join("records.cfg")
	s.path = scratch.path_join("settings.cfg")
	s.load_settings()
	_check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/title.tscn", "la escena inicial es el título")
	change_scene_to_file("res://scenes/title.tscn")
	await scene_changed
	var title := current_scene
	_check(title._play.text == "Tocá para jugar", "muestra Tocá para jugar")
	_check(title._play.has_focus(), "el foco arranca en jugar")
	_check(title._accents.size() == 4 and title._accents[1] == state.active_theme(state.NAUTILUS).select_accent, "colores de los TableTheme")
	title._options_button.pressed.emit()
	_check(title._options.is_open(), "Opciones se abre")
	title.start()
	_check(current_scene == title, "con opciones abiertas no arranca")
	title._options._back.pressed.emit()
	_check(not title._options.is_open() and title._options_button.has_focus(), "Volver cierra y devuelve el foco")
	var tap := InputEventMouseButton.new()
	tap.button_index = MOUSE_BUTTON_LEFT
	tap.pressed = true
	title._gui_input(tap)
	await scene_changed
	_check(current_scene.scene_file_path == "res://scenes/table_select.tscn", "tocar abre el selector")
	change_scene_to_file("res://scenes/title.tscn")
	await scene_changed
	current_scene._records_button.pressed.emit()
	await scene_changed
	_check(current_scene.scene_file_path == "res://scenes/records.tscn", "Récords abre la pantalla de récords")
	current_scene.free()
	var dir := DirAccess.open(scratch)
	if dir:
		for file in dir.get_files(): dir.remove(file)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch))
	quit(1 if failures else 0)


func _check(ok: bool, message: String) -> void:
	print(("OK: " if ok else "FALLÓ: ") + message)
	if not ok: failures += 1
