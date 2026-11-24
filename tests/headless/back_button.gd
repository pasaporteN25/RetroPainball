extends SceneTree
## P-04: el botón atrás de Android navega hacia atrás en cada pantalla del menú
## (récords → selector → título; en el título cierra las opciones antes de salir).

var failures := 0
var scratch := "user://test_back_%d" % OS.get_process_id()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	var s := root.get_node("Settings")
	state.save_directory = scratch
	state.record_path = scratch.path_join("records.cfg")
	s.path = scratch.path_join("settings.cfg")
	s.load_settings()

	change_scene_to_file("res://scenes/records.tscn")
	await scene_changed
	current_scene.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await scene_changed
	_check(current_scene.scene_file_path == "res://scenes/table_select.tscn", "atrás en Récords vuelve al selector")

	current_scene.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await scene_changed
	_check(current_scene.scene_file_path == "res://scenes/title.tscn", "atrás en el selector vuelve al título")

	var title := current_scene
	title.open_options()
	_check(title._options.is_open(), "las opciones se abren desde el título")
	title.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_check(not title._options.is_open() and current_scene == title, "atrás cierra las opciones sin salir del juego")
	_check(not ProjectSettings.get_setting("application/config/quit_on_go_back"),
		"Godot no cierra solo: cada pantalla decide qué hace atrás")

	change_scene_to_file("res://scenes/table_select.tscn")
	await scene_changed
	var event := InputEventAction.new()
	event.action = &"ui_cancel"
	event.pressed = true
	root.push_input(event)
	await scene_changed
	_check(current_scene.scene_file_path == "res://scenes/title.tscn", "Esc en el selector vuelve al título")

	current_scene.free()
	var dir := DirAccess.open(scratch)
	if dir:
		for file in dir.get_files(): dir.remove(file)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch))
	print("back_button: %d fallas" % failures)
	quit(1 if failures else 0)


func _check(ok: bool, message: String) -> void:
	print(("OK: " if ok else "FALLÓ: ") + message)
	if not ok:
		failures += 1
