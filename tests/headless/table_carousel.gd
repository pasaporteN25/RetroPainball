extends SceneTree
## U-04: máquinas, rebote, gestos, récords y navegación del carrusel.

const GameSave := preload("res://scripts/util/game_save.gd")
const SELECT_SCENE := "res://scenes/table_select.tscn"

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
	cfg.set_value("top/dracula", "entries", [{"score": 8100, "initials": "ABC"}])
	_check(cfg.save(state.record_path) == OK, "se preparan los récords por mesa")
	var snapshot := {
		"table_id": state.NAUTILUS, "score": 6200, "balls_left": 2, "balls": [],
		"serve_remaining": 0.6, "save_remaining": 0.0, "save_armed": false,
		"sonar_mask": 1, "depth": 1500,
	}
	_check(GameSave.save_run(snapshot, scratch) == OK, "se prepara la partida guardada")
	create_timer(12.0).timeout.connect(_timeout)

	change_scene_to_file(SELECT_SCENE)
	await scene_changed
	var selector := current_scene
	_check(selector._machines.size() == 4 and selector._selected == 0, "cuatro mesas y Kernel Panic seleccionado")
	_check(not selector._continue.visible, "Continuar queda oculto sin partida")
	_check_layout(selector)

	_click(selector._next.get_global_rect().get_center())
	_check(selector._selected == 1, "la flecha en pantalla selecciona Nautilus")
	var bounced := false
	while selector._transition.is_running():
		await process_frame
		bounced = bounced or selector._display_index > 1.005
	_check(bounced and is_equal_approx(selector._display_index, 1.0), "el Tween rebota y termina centrado")
	_check_layout(selector)
	_check(selector._record.text == "RÉCORD  12345", "el cartel lee el récord histórico de Nautilus")
	_check(selector._continue.visible and selector._table_name.text == "20.000 Leguas", "el cartel muestra nombre y Continuar")

	var center: Vector2 = selector._machines[1].get_global_rect().get_center()
	_touch(center, true)
	_touch(center - Vector2(100, 0), false)
	await process_frame
	_check(current_scene == selector and selector._selected == 2, "el swipe táctil cambia de mesa sin jugar")
	await selector._transition.finished
	_check(selector._record.text == "RÉCORD  8100", "el cartel admite un top antiguo y muestra solo el puntaje")
	_check(not selector._continue.visible, "Continuar se oculta al elegir una mesa sin guardado")

	center = selector._machines[2].get_global_rect().get_center()
	_mouse_button(center, true)
	var motion := InputEventMouseMotion.new()
	motion.position = center - Vector2(80, 0)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(motion, true)
	_mouse_button(motion.position, false)
	await process_frame
	_check(current_scene == selector and selector._selected == 3, "el arrastre con mouse tampoco entra a la mesa")

	_joy_button(JOY_BUTTON_DPAD_RIGHT)
	_check(selector._selected == 0, "la cruceta pasa de Alicia a Kernel Panic")
	await selector._transition.finished
	_check_layout(selector)
	_check(selector._machines[0].has_focus(), "Kernel Panic recibe foco después de dos cambios rápidos")
	_click(selector._machines[3].get_global_rect().get_center())
	_check(selector._selected == 3 and current_scene == selector, "tocar una máquina lateral la selecciona")
	await selector._transition.finished
	_joy_button(JOY_BUTTON_A)
	await scene_changed
	_check(current_scene.scene_file_path == "res://scenes/alicia.tscn", "confirmar con el mando abre la mesa elegida")

	change_scene_to_file(SELECT_SCENE)
	await scene_changed
	selector = current_scene
	_click(selector._records.get_global_rect().get_center())
	await scene_changed
	_check(current_scene.scene_file_path == "res://scenes/records.tscn", "Récords abre su pantalla")
	current_scene.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await scene_changed
	selector = current_scene
	_check(selector.scene_file_path == SELECT_SCENE, "atrás en Récords vuelve al selector")
	_click(selector._next.get_global_rect().get_center())
	_joy_button(JOY_BUTTON_DPAD_DOWN)
	_check(selector._continue.has_focus(), "la cruceta baja al botón Continuar")
	_click(selector._continue.get_global_rect().get_center())
	await scene_changed
	_check(current_scene.scene_file_path == "res://scenes/nautilus.tscn"
		and state.score == 6200 and state.balls_left == 2, "Continuar abre Nautilus y restaura la partida")

	change_scene_to_file(SELECT_SCENE)
	await scene_changed
	selector = current_scene
	center = selector._machines[0].get_global_rect().get_center()
	_touch(center, true)
	_touch(center, false)
	await scene_changed
	_check(current_scene.scene_file_path == "res://scenes/main.tscn" and state.score == 0,
		"tocar la máquina central inicia una partida nueva")

	current_scene.free()
	for table_id: String in [state.KERNEL_PANIC, state.NAUTILUS, state.ALICIA]:
		GameSave.clear_run(table_id, scratch)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(state.record_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch))
	quit(1 if failures else 0)


func _check_layout(selector: Control) -> void:
	var machines: Array = selector._machines
	var selected: int = selector._selected
	var active: Control = machines[selected]
	var previous: Control = machines[posmod(selected - 1, machines.size())]
	var next: Control = machines[posmod(selected + 1, machines.size())]
	var opposite: Control = machines[posmod(selected + 2, machines.size())]
	_check(active.visible and previous.visible and next.visible and not opposite.visible,
		"se ven exactamente la elegida y sus dos vecinas")
	_check(active.position.x > previous.position.x and active.position.x < next.position.x
		and active.z_index > previous.z_index and active.z_index > next.z_index,
		"la máquina elegida queda al centro y al frente")
	_check(active.scale.x > previous.scale.x and active.scale.x > next.scale.x
		and active.modulate.r > previous.modulate.r and active.modulate.r > next.modulate.r,
		"las máquinas vecinas son más chicas y atenuadas")
	_check(active.rotation == 0.0 and previous.rotation == 0.0 and next.rotation == 0.0
		and active.size == previous.size and active.size == next.size, "mismo gabinete en cada mesa, sin rotación")


func _mouse_button(point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.pressed = pressed
	root.push_input(event, true)


func _click(point: Vector2) -> void:
	_mouse_button(point, true)
	_mouse_button(point, false)


func _touch(point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.position = root.get_final_transform() * point
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _joy_button(button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	root.push_input(event)
	event = InputEventJoypadButton.new()
	event.button_index = button
	root.push_input(event)


func _timeout() -> void:
	_check(false, "el carrusel agotó el tiempo de espera")
	quit(1)


func _check(ok: bool, message: String) -> void:
	print(("OK: " if ok else "FALLÓ: ") + message)
	if not ok:
		failures += 1
