extends SceneTree

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, detail: String) -> void:
	if not condition:
		failures += 1
		printerr("FALLÓ: " + detail)

func _run() -> void:
	var state := root.get_node("GameState")
	var scratch := "user://test_hud_%d" % OS.get_process_id()
	state.save_directory = scratch
	state.record_path = scratch + "/records.cfg"
	var hud = load("res://scripts/ui/hud.gd").new()
	root.add_child(hud)
	hud.show_message("primero")
	hud.show_message("viejo")
	hud.show_message("¡JACKPOT!")
	hud.show_message("medio")
	hud.show_message("nuevo")
	check(hud._message.text == "primero", "el aviso activo no se pisa")
	check(hud._message_queue.size() == 3 and hud._message_queue[0].text == "¡JACKPOT!", "se descarta el aviso común más viejo")
	await create_timer(0.92).timeout
	check(hud._message.text == "primero", "el aviso dura al menos 0,9 segundos")
	await create_timer(0.55).timeout
	check(hud._message.text == "¡JACKPOT!", "el jackpot aparece en orden")
	await create_timer(0.25).timeout
	check(hud._message.modulate.a < 1.0, "el jackpot parpadea")
	hud._on_game_started()
	state.bonus_awarded.emit(100, 3, 300)
	state.message.emit("BONUS 100 X3")
	check(hud._message_queue.is_empty(), "el aviso de bonus no se duplica")
	await create_timer(0.55).timeout
	check(hud._message.text != "BONUS 100  X3" and hud._message.text != "BONUS 300  X3", "el bonus cuenta valores intermedios")
	await create_timer(0.45).timeout
	check(hud._message.text == "BONUS 300  X3", "el bonus alcanza el total")
	hud.queue_free()
	await process_frame
	print("HUD: %d fallos" % failures)
	quit(1 if failures else 0)
