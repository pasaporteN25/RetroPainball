extends SceneTree
## U-07: la pausa abre las opciones; los cambios se aplican y persisten; la vibración y las zonas respetan la opción.

var failures := 0
var scratch := "user://test_options_%d" % OS.get_process_id()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	var s := root.get_node("Settings")
	state.save_directory = scratch
	state.record_path = scratch.path_join("records.cfg")
	s.path = scratch.path_join("settings.cfg")
	s.load_settings()
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	var hud := current_scene.get_node("HUD")
	var menu := hud.get_node("PauseMenu")
	var options := menu.get_node("OptionsMenu")
	hud.toggle_pause()
	_check(not options.is_open(), "opciones cerradas al pausar")
	menu._buttons[2].pressed.emit()
	_check(options.is_open() and menu._buttons[2].text == "Opciones", "Opciones se abre desde la pausa")
	options._sliders[&"Efectos"].value = 0.25
	_check(is_equal_approx(s.volumes[&"Efectos"], 0.25), "slider cambia el volumen")
	options._vibration.pressed.emit()
	_check(not s.vibration, "botón apaga la vibración")
	options._zone.pressed.emit()
	var touch := current_scene.get_node("TouchControls")
	_check(s.touch_zone == "baja" and is_equal_approx(touch.zone_top_ratio, 0.7), "zona táctil baja llega a TouchControls")
	options._language.pressed.emit()
	_check(s.language == "en", "idioma guarda preferencia")
	options._back.pressed.emit()
	_check(not options.is_open() and FileAccess.file_exists(s.path), "Volver cierra y guarda")
	s.set_vibration(true)
	s.load_settings()
	_check(not s.vibration and s.touch_zone == "baja" and s.language == "en", "persistido en el archivo de prueba")
	menu._buttons[0].pressed.emit()
	_check(not paused, "Continuar reanuda tras opciones")
	current_scene.free()
	var dir := DirAccess.open(scratch)
	if dir:
		for file in dir.get_files(): dir.remove(file)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch))
	s.path = "user://test_settings_unused.cfg"
	s.load_settings()
	s.apply()
	quit(1 if failures else 0)


func _check(ok: bool, message: String) -> void:
	print(("OK: " if ok else "FALLÓ: ") + message)
	if not ok:
		failures += 1
