extends SceneTree
## Modo de pruebas (Q-02): apagado por defecto, multibola en cada mesa con sus propias reglas,
## bola infinita, overlay de colisiones y velocidad del juego.

var TestMode: GDScript
var failures := 0
var scratch := "user://test_test_mode_%d" % OS.get_process_id()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	TestMode = load("res://scripts/util/test_mode.gd")
	var state := root.get_node("GameState")
	state.save_directory = ""
	state.record_path = scratch.path_join("records.cfg")
	_check(not TestMode.is_enabled(), "apagado sin el flag --test-mode")
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	_check(current_scene.get_node_or_null("TestMode") == null, "no se crea sin el flag")
	current_scene.free()
	TestMode.force_enabled = true
	for path in ["res://scenes/main.tscn", "res://scenes/nautilus.tscn", "res://scenes/dracula.tscn"]:
		await _table(path)
	Engine.time_scale = 1.0
	quit(1 if failures else 0)


func _table(path: String) -> void:
	var state := root.get_node("GameState")
	change_scene_to_file(path)
	await scene_changed
	var main := current_scene
	var mode := main.get_node_or_null("TestMode")
	if not _check(mode != null, "%s: crea TestMode con el flag" % path):
		return
	await create_timer(0.9).timeout
	_check(main.ball_count() == 1, "%s: una bola sacada" % path)
	# Velocidad
	_check(mode.handle_key(KEY_F4) and Engine.time_scale == 2.0, "%s: F4 pasa a 2x" % path)
	mode.handle_key(KEY_F4)
	_check(Engine.time_scale == 0.25, "%s: F4 vuelve a 0.25x" % path)
	mode.set_speed_index(TestMode.NORMAL_SPEED_INDEX)
	_check(Engine.time_scale == 1.0, "%s: 1x" % path)
	# Colisiones
	mode.handle_key(KEY_F3)
	var overlay := main.get_node("Table").get_node_or_null("CollisionOverlay")
	_check(overlay != null and overlay.visible, "%s: F3 muestra colisiones" % path)
	await process_frame
	mode.handle_key(KEY_F3)
	_check(not overlay.visible, "%s: F3 las oculta" % path)
	# Multibola
	var own: bool = mode.jump_to_multiball()
	await physics_frame
	await physics_frame
	_check(main.ball_count() >= 2, "%s: F1 deja varias bolas (%d)" % [path, main.ball_count()])
	_check(own == (path != "res://scenes/main.tscn"), "%s: usa la multibola propia de la mesa" % path)
	var rules := main.get_node_or_null("Table/DraculaRules")
	if rules:
		_check(rules.midnight, "Drácula: Medianoche activa")
	# Bola infinita: drenar todo no gasta bolas
	mode.handle_key(KEY_F2)
	_check(main.infinite_balls, "%s: F2 activa bola infinita" % path)
	var left: int = state.balls_left
	for ball in main.get_node("Table/Balls").get_children():
		main._on_drain(ball)
	await create_timer(1.0).timeout
	_check(state.balls_left == left and state.playing and main.ball_count() == 1, "%s: sin perder bola, sirve otra" % path)
	_check(state.last_bonus_award == 0, "%s: no cobra bonus" % path)
	mode.handle_key(KEY_F2)
	_check(not main.infinite_balls, "%s: F2 la apaga" % path)
	_check(not mode.handle_key(KEY_F9), "%s: ignora otras teclas" % path)
	current_scene.free()
	_check(Engine.time_scale == 1.0, "%s: time_scale vuelve a 1" % path)


func _check(ok: bool, message: String) -> bool:
	print(("OK: " if ok else "FALLÓ: ") + message)
	if not ok: failures += 1
	return ok
