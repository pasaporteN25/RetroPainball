extends SceneTree
## Atrás coherente: la notificación de Android y Esc hacen lo mismo en cada pantalla, y nunca dos veces.

const BackNav := preload("res://scripts/util/back_nav.gd")
var scratch := "user://test_back_%d" % OS.get_process_id()
var failures := 0
var quits := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	var s := root.get_node("Settings")
	state.save_directory = scratch
	state.record_path = scratch.path_join("records.cfg")
	s.path = scratch.path_join("settings.cfg")
	s.load_settings()
	await _title()
	await _selector_and_records()
	await _table()
	var dir := DirAccess.open(scratch)
	if dir:
		for file in dir.get_files(): dir.remove(file)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch))
	quit(1 if failures else 0)


func _go(path: String) -> void:
	change_scene_to_file(path)
	await scene_changed
	await process_frame


func _title() -> void:
	await _go("res://scenes/title.tscn")
	var title := current_scene
	title.quit_app = func() -> void: quits += 1
	_android_back()
	_key_back()
	_check(title.exit_armed() and title._exit_hint.visible and quits == 0, "título: atrás avisa y Android + Esc en el mismo frame cuentan una vez")
	await process_frame
	_android_back()
	_check(quits == 1, "título: el segundo atrás sale de la app")
	title._exit_until = -1.0
	await process_frame
	_key_back()
	_check(title.exit_armed() and quits == 1, "título: Esc también avisa primero")
	title._exit_until = -1.0
	await process_frame
	_check(not title.exit_armed() and current_scene == title, "título: el aviso vence y no cambia de pantalla")
	title.open_options()
	await process_frame
	_android_back()
	_check(not title._options.is_open() and not title.exit_armed() and current_scene == title, "título: atrás cierra las opciones sin salir")
	await process_frame
	title.open_options()
	await process_frame
	_key_back()
	_check(not title._options.is_open() and not title.exit_armed(), "título: Esc cierra las opciones sin salir")
	await process_frame
	title._records_button.pressed.emit()
	await scene_changed
	await process_frame
	_check(current_scene.scene_file_path == "res://scenes/records.tscn", "título: Récords abre la lista")
	_android_back()
	await scene_changed
	_check(current_scene.scene_file_path == BackNav.TITLE_SCENE, "récords abierto desde el título: atrás vuelve al título")


func _selector_and_records() -> void:
	await _go(BackNav.SELECT_SCENE)
	_android_back()
	_key_back()
	await scene_changed
	_check(current_scene.scene_file_path == BackNav.TITLE_SCENE, "selector: atrás (Android + Esc a la vez) vuelve al título")
	await _go(BackNav.SELECT_SCENE)
	_key_back()
	await scene_changed
	_check(current_scene.scene_file_path == BackNav.TITLE_SCENE, "selector: Esc vuelve al título")
	await _go(BackNav.SELECT_SCENE)
	current_scene._records.pressed.emit()
	await scene_changed
	await process_frame
	_key_back()
	await scene_changed
	_check(current_scene.scene_file_path == BackNav.SELECT_SCENE, "récords abierto desde el selector: Esc vuelve al selector")
	await process_frame
	await _go("res://scenes/records.tscn")
	_android_back()
	await scene_changed
	_check(current_scene.scene_file_path == BackNav.SELECT_SCENE, "récords: atrás de Android vuelve al selector")


func _table() -> void:
	var state := root.get_node("GameState")
	await _go("res://scenes/main.tscn")
	var hud := current_scene.get_node("HUD")
	var menu := hud.get_node("PauseMenu")
	_check(state.playing and not paused, "mesa: arranca jugando")
	_android_back()
	_check(paused and menu._shade.visible, "mesa: atrás abre la pausa")
	await process_frame
	_android_back()
	_key_back()
	_check(not paused and not menu._shade.visible, "mesa: atrás cierra la pausa y continúa (un solo toggle por frame)")
	await process_frame
	_key_back()
	_check(paused, "mesa: Esc abre la pausa")
	await process_frame
	_key_back()
	_check(not paused, "mesa: Esc cierra la pausa")
	await process_frame
	_android_back()
	await process_frame
	menu._buttons[2].pressed.emit()
	await process_frame
	_check(menu.options_open(), "mesa: opciones abiertas desde la pausa")
	_android_back()
	_check(not menu.options_open() and paused, "mesa: atrás cierra las opciones y deja la pausa")
	await process_frame
	menu._buttons[2].pressed.emit()
	await process_frame
	_key_back()
	_check(not menu.options_open() and paused, "mesa: Esc cierra las opciones y deja la pausa")
	await process_frame
	_check(menu._buttons[3].text == "Mesas", "la pausa tiene el botón Mesas")
	menu._buttons[3].pressed.emit()
	await scene_changed
	_check(not paused and current_scene.scene_file_path == BackNav.SELECT_SCENE, "pausa: Mesas vuelve al selector")
	await process_frame
	await _go("res://scenes/main.tscn")
	hud = current_scene.get_node("HUD")
	state.playing = false
	hud._game_over.show()
	await process_frame
	_android_back()
	await scene_changed
	_check(current_scene.scene_file_path == BackNav.SELECT_SCENE, "fin de partida: atrás vuelve al selector")


func _android_back() -> void:
	root.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)


func _key_back() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	root.push_input(event)


func _check(ok: bool, message: String) -> void:
	print(("OK: " if ok else "FALLÓ: ") + message)
	if not ok:
		failures += 1
