extends SceneTree
## U-03: escena inicial, modo atracción, fundido y navegación del título.

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
	_check(title._insert_colors[1] == state.active_theme(state.NAUTILUS).lamp_tint, "los insertos usan el color de lámpara del tema")
	_check(title._insert_level(0, 0.0) > title._insert_level(1, 0.0)
		and title._insert_level(1, 0.62) > title._insert_level(0, 0.62), "la luz pasa de un inserto al siguiente")
	_check(title._tube_level(2.20) < title._tube_level(1.80)
		and is_equal_approx(title._tube_level(2.20), title._tube_level(9.60)), "el falso contacto del tubo se repite")
	_check(title._ball_at(0.0).distance_to(title._ball_at(0.2)) > 20.0, "la bola recorre el tablero")
	var loop_time: float = title._route_length / title.BALL_SPEED
	_check(title._ball_at(-0.05).distance_to(title._ball_at(loop_time - 0.05)) < 0.01, "la estela sigue la vuelta desde el comienzo")
	var original_bottom: float = title.offset_bottom
	var original_right: float = title.offset_right
	for phone_size in [Vector2(720, 1280), Vector2(720, 1720)]:
		title.offset_bottom += phone_size.y - title.size.y
		title.offset_right += phone_size.x - title.size.x
		var art_end: Vector2 = title._art_origin + title.ART_SIZE * title._art_scale
		var safe_area := Rect2(Vector2.ZERO, phone_size)
		_check(title.size == phone_size
			and safe_area.encloses(Rect2(title._art_origin, title.ART_SIZE * title._art_scale))
			and art_end.y < title._play.position.y
			and safe_area.encloses(title._records_button.get_rect()), "arte y controles dentro de la pantalla %d × %d" % [phone_size.x, phone_size.y])
	title.offset_bottom = original_bottom
	title.offset_right = original_right
	title._options_button.pressed.emit()
	_check(title._options.is_open() and not title.is_processing(), "Opciones se abre y pausa el modo atracción")
	title.start()
	_check(current_scene == title and not title._transition.visible, "con opciones abiertas no arranca")
	title._options._back.pressed.emit()
	_check(not title._options.is_open() and title._options_button.has_focus() and title.is_processing(), "Volver cierra, devuelve el foco y reanuda la animación")
	var tap := InputEventScreenTouch.new()
	tap.position = Vector2(30, 30)
	tap.pressed = true
	root.push_input(tap, true)
	_check(current_scene == title and title._transition.visible, "tocar inicia el fundido en el título")
	title._options_button.pressed.emit()
	title._records_button.pressed.emit()
	_check(not title._options.is_open() and current_scene == title, "el fundido bloquea otras rutas")
	await create_timer(title.FADE_TIME + 0.15).timeout
	_check(current_scene != null and current_scene.scene_file_path == "res://scenes/table_select.tscn", "el fundido abre el selector")
	change_scene_to_file("res://scenes/title.tscn")
	await scene_changed
	title = current_scene
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = title._play.get_rect().get_center()
	click.pressed = true
	root.push_input(click, true)
	click.pressed = false
	root.push_input(click, true)
	_check(title._transition.visible, "el botón Tocá para jugar también inicia el fundido")
	await create_timer(title.FADE_TIME + 0.15).timeout
	_check(current_scene != null and current_scene.scene_file_path == "res://scenes/table_select.tscn", "el botón abre el selector")
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
