extends SceneTree

const SAVE := preload("res://scripts/util/game_save.gd")
var scratch := "user://test_pause_%d" % OS.get_process_id()
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_directory = scratch
	state.record_path = scratch.path_join("records.cfg")
	var baseline := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	var hud := current_scene.get_node("HUD")
	var menu := hud.get_node("PauseMenu")
	state.add_score(123, Vector2.ZERO)
	hud.toggle_pause()
	_check(paused and menu._shade.visible, "pausa y muestra el menú")
	_check(SAVE.load_run("kernel_panic", scratch).get("score") == 123, "guarda al pausar")
	_check(menu._buttons[0].has_focus(), "enfoca Continuar")
	menu._buttons[0].pressed.emit()
	_check(not paused and not menu._shade.visible, "Continuar reanuda")
	hud.toggle_pause()
	menu._buttons[1].pressed.emit()
	_check(not paused and state.score == 0 and state.playing, "Reiniciar comienza otra partida")
	hud.toggle_pause()
	menu._buttons[2].pressed.emit()
	await scene_changed
	_check(not paused and current_scene.scene_file_path == "res://scenes/table_select.tscn", "Volver abre el selector")
	current_scene.free()
	_check(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) == baseline, "sin nodos huérfanos")
	var dir := DirAccess.open(scratch)
	if dir:
		for file in dir.get_files(): dir.remove(file)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch))
	quit(1 if failures else 0)

func _check(ok: bool, message: String) -> void:
	print(("OK: " if ok else "FALLÓ: ") + message)
	if not ok: failures += 1
