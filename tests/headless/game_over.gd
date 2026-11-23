extends SceneTree
## U-06: pantalla de fin de partida con puntaje, bonus, puesto en el top 10 (sin nombres) y salidas.

var scratch := "user://test_gameover_%d" % OS.get_process_id()
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(scratch)
	var state := root.get_node("GameState")
	state.save_directory = ""
	state.record_path = scratch.path_join("records.cfg")
	root.content_scale_size = Vector2i(720, 1280)
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	var hud := current_scene.get_node("HUD")
	var over: Control = hud._game_over
	state.start_game()
	state.add_score(5000, Vector2.ZERO)
	state.lose_ball()
	state.lose_ball()
	state.add_score(1000, Vector2.ZERO)
	state.lose_ball()
	_check(not state.playing and over.visible, "al perder la última bola se muestra el fin de partida")
	_check(hud._go_bonus.text.contains("BONUS COBRADO"), "muestra el bonus cobrado")
	_check(state.bonus_total > 0 and state.last_result["bonus_total"] == state.bonus_total, "el bonus total queda en el resultado")
	_check(state.last_result["rank"] == 1 and state.top_scores()[0]["score"] == state.last_result["score"], "entra al top y se guarda sin pedir nada")
	_check(hud._go_record.text.contains("RÉCORD") or hud._go_record.text.contains("PUESTO 1"), "muestra el récord")
	_check(hud._go_play.has_focus(), "el foco queda en Otra partida")
	_check(root.get_visible_rect().encloses(hud._game_over_card.get_global_rect()), "la tarjeta entra en pantalla")
	_press_pad(JOY_BUTTON_DPAD_DOWN)
	_check(hud._go_tables.has_focus(), "la cruceta baja a Mesas")
	_press_pad(JOY_BUTTON_DPAD_UP)
	_check(hud._go_play.has_focus(), "y vuelve a Otra partida")

	hud._go_play.pressed.emit()
	_check(state.playing and state.score == 0 and not over.visible, "Otra partida reinicia la misma mesa")
	_check(state.table_id == "kernel_panic", "la mesa no cambia")
	state.end_game()
	_check(over.visible and hud._go_record.text.contains("RÉCORD") and hud._go_play.has_focus(), "sin puntos muestra el récord y enfoca Otra partida")

	state.start_game()
	state.add_score(100, Vector2.ZERO)
	state.end_game()
	_check(state.last_result["rank"] == 2, "otro puntaje entra en su puesto")
	hud._go_tables.pressed.emit()
	await scene_changed
	_check(current_scene.scene_file_path == "res://scenes/table_select.tscn", "Mesas vuelve al selector")
	_check(state.top_scores().size() == 2, "el puntaje ya estaba guardado al salir")

	current_scene.get_node("Records").pressed.emit()
	await scene_changed
	_check(current_scene.scene_file_path == "res://scenes/records.tscn", "el selector abre la pantalla de récords")
	var rows: Array[String] = current_scene.row_texts()
	_check(rows[0].ends_with("6.600") and not rows[0].contains("AAA") and rows[1].contains("100") and rows[2].contains("·") and not rows[0].contains("AAA"), "lista el top de la mesa")
	current_scene.show_table("nautilus")
	_check(current_scene.row_texts()[0].contains("·"), "cada mesa muestra su propio top")
	current_scene._back.pressed.emit()
	await scene_changed
	_check(current_scene.scene_file_path == "res://scenes/table_select.tscn", "Volver regresa al selector")
	current_scene.free()

	var dir := DirAccess.open(scratch)
	if dir:
		for file in dir.get_files():
			dir.remove(file)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch))
	quit(1 if failures else 0)


func _press_pad(button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	root.push_input(event)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event)


func _check(ok: bool, message: String) -> void:
	print(("OK: " if ok else "FALLÓ: ") + message)
	if not ok:
		failures += 1
