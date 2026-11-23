extends SceneTree
## Pulido de Drácula: selector con 3 tarjetas completas en varias resoluciones, candelabros solo en Drácula
## y piezas que dibujan todos sus estados. Usa directorios descartables.

var _failures := 0
var _scratch := "user://test_art_dracula_polish_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node("GameState")
	game.record_path = _scratch.path_join("records.cfg")
	game.save_directory = _scratch
	await _test_selector()
	await _test_pieces(game)
	await _test_bumper_variants(game)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_scratch))
	print("Pulido Drácula: %d fallos" % _failures)
	quit(1 if _failures else 0)


func _test_selector() -> void:
	change_scene_to_file("res://scenes/table_select.tscn")
	await scene_changed
	var select := current_scene
	var cards: Array[Control] = [select._kernel, select._nautilus, select._dracula, select._alicia]
	# El proyecto estira con ancho fijo (720): 620x1343 -> 720x1560, 720x1280 -> 720x1280, 540x960 -> 720x960.
	for resolution in [Vector2i(720, 1560), Vector2i(720, 1280), Vector2i(720, 960)]:
		select.set_deferred("size", Vector2(resolution))
		await process_frame
		select.size = Vector2(resolution)
		select._layout()
		var view := Rect2(Vector2.ZERO, Vector2(resolution))
		var inside := true
		var previous_bottom := 0.0
		var ordered := true
		for card in cards:
			var rect := Rect2(card.global_position, card.size * card.scale)
			inside = inside and view.grow(0.5).encloses(rect)
			ordered = ordered and rect.position.y >= previous_bottom - 0.5
			previous_bottom = rect.end.y
		_check(inside, "las 4 tarjetas entran completas en %s" % resolution)
		_check(ordered and view.size.y - previous_bottom >= 8.0, "tarjetas sin solaparse y con margen inferior en %s" % resolution)
		_check(cards[3].scale.x > 0.4, "las tarjetas no se achican de más en %s (zoom %.2f)" % [resolution, cards[2].scale.x])
	# Foco entre las 3 tarjetas con teclado/gamepad.
	select._kernel.grab_focus()
	_check(select._kernel.focus_neighbor_bottom == select._kernel.get_path_to(select._nautilus), "foco Kernel -> Nautilus")
	_check(select._nautilus.focus_neighbor_bottom == select._nautilus.get_path_to(select._dracula), "foco Nautilus -> Drácula")
	_check(select._dracula.focus_neighbor_top == select._dracula.get_path_to(select._nautilus), "foco Drácula -> Nautilus")
	_check(select._dracula.focus_neighbor_bottom == select._dracula.get_path_to(select._alicia), "foco Drácula -> Alicia")
	_check(select._alicia.focus_neighbor_top == select._alicia.get_path_to(select._dracula), "foco Alicia -> Drácula")
	select._dracula.grab_focus()
	await process_frame
	_check(select._dracula.has_focus(), "Drácula toma el foco")


func _test_pieces(game: Node) -> void:
	change_scene_to_file("res://scenes/dracula.tscn")
	await scene_changed
	await create_timer(0.3).timeout
	var table := current_scene.get_node("Table")
	var rules := table.get_node("DraculaRules")
	var art := table.get_node("PlayfieldArt")
	_check(art.get_node_or_null("Ambient") != null, "el arte tiene su capa dinámica")
	for bat in table.get_node("Bats").get_children():
		bat.set_activated(true)
		bat.queue_redraw()
		bat.set_activated(false)
	var coffin := table.get_node("Coffin")
	coffin.lock_lit = true
	coffin.lock_lit = false
	var portrait := table.get_node("Portrait")
	portrait.jackpot_ready = true
	await process_frame
	portrait.jackpot_ready = false
	for stage in 3:
		table.get_node("Carfax").set_stage(stage)
	rules.midnight_started.emit()
	rules.lock_lit_changed.emit(true)
	art.pulse_score()
	art.flash_jackpot()
	art.set_ball_save_fraction(0.5)
	await create_timer(0.3).timeout
	rules.midnight_ended.emit()
	rules.lock_lit_changed.emit(false)
	await process_frame
	_check(art._bands.size() > 20, "el fondo se recorta a bandas del contorno del campo")
	var inside := true
	for band in art._bands:
		for point in band:
			inside = inside and point.x >= 15.5 and point.x <= 708.5 and point.y <= 1441.0
	_check(inside, "las bandas del fondo quedan dentro del contorno")


func _test_bumper_variants(game: Node) -> void:
	var bumper = (load("res://scripts/table/bumper.gd") as GDScript).new()
	bumper.position = Vector2(210, 610)
	root.add_child(bumper)
	game.table_id = game.DRACULA
	for i in 6:
		await process_frame
	_check(bumper._flame_time > 0.0, "el candelabro anima su llama en Drácula")
	_check(bumper._blink_time == 0.0, "Drácula no usa el parpadeo del daemon")
	bumper._flash = 1.0
	await process_frame
	_check(not bumper._flame_shape.is_empty(), "la llama se dibuja")
	var other = (load("res://scripts/table/bumper.gd") as GDScript).new()
	root.add_child(other)
	game.table_id = game.NAUTILUS
	for i in 6:
		await process_frame
	_check(other._flame_time == 0.0 and other._blink_time == 0.0, "Nautilus no recibe variante ni animación extra")
	game.table_id = game.KERNEL_PANIC
	var before: float = other._flame_time
	for i in 6:
		await process_frame
	_check(other._flame_time == before and other._blink_time > 0.0, "Kernel Panic conserva su daemon")
	bumper.queue_free()
	other.queue_free()
	await process_frame


func _check(ok: bool, description: String) -> void:
	print("[%s] %s" % ["PASS" if ok else "FAIL", description])
	if not ok:
		_failures += 1
