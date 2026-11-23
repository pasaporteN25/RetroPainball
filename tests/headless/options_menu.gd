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
	root.content_scale_size = Vector2i(720, 1280)
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	var hud := current_scene.get_node("HUD")
	var menu := hud.get_node("PauseMenu")
	var options := menu.get_node("OptionsMenu")
	hud.toggle_pause()
	_check(not options.is_open(), "opciones cerradas al pausar")
	menu._buttons[2].pressed.emit()
	_check(options.is_open() and menu._buttons[2].text == "Opciones", "Opciones se abre desde la pausa")
	await process_frame
	await process_frame
	_check(root.get_visible_rect().encloses(options._panel.get_global_rect()), "opciones entra en un viewport vertical 9:16")
	_check(options._back.has_focus(), "Volver recibe el foco al abrir")
	_press_key(KEY_DOWN)
	_check(options._sliders[&"Música"].has_focus(), "abajo en Volver enfoca el primer volumen")
	_press_key(KEY_DOWN)
	var slider: HSlider = options._sliders[&"Efectos"]
	_check(slider.has_focus() and slider.has_theme_stylebox_override("focus"), "el slider tiene foco visible")
	slider.value = 0.30
	_press_key(KEY_LEFT)
	_check(slider.has_focus() and is_equal_approx(s.volumes[&"Efectos"], 0.25), "izquierda ajusta el volumen sin perder foco")
	_check(options._readouts[&"Efectos"].text == "25%", "se actualiza el porcentaje")
	options._vibration.pressed.emit()
	_check(not s.vibration, "botón apaga la vibración")
	options._zone.pressed.emit()
	var touch := current_scene.get_node("TouchControls")
	_check(s.touch_zone == "baja" and is_equal_approx(touch.zone_top_ratio, 0.7), "zona táctil baja llega a TouchControls")
	options._language.pressed.emit()
	_check(s.language == "en", "idioma guarda preferencia")
	options._back.pressed.emit()
	_check(not options.is_open() and FileAccess.file_exists(s.path), "Volver cierra y guarda")
	_check(menu._buttons[2].has_focus(), "al cerrar, el foco vuelve a Opciones en la pausa")
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


func _press_key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	root.push_input(event)


func _check(ok: bool, message: String) -> void:
	print(("OK: " if ok else "FALLÓ: ") + message)
	if not ok:
		failures += 1
