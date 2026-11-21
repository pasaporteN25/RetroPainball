extends SceneTree
## G-05: los rollovers superiores de Kernel Panic se encienden, rotan con los flippers y premian.

const SCENE := "res://scenes/main.tscn"
var _state: Node
var _checks := 0
var _failures := 0
var _scratch := "user://test_kernel_rollovers_%d" % OS.get_process_id()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_state = root.get_node("GameState")
	_state.save_directory = _scratch
	_state.record_path = _scratch.path_join("records.cfg")
	_state.select_table("kernel_panic")
	if not _check(change_scene_to_file(SCENE) == OK, "Kernel Panic carga la mesa"):
		_finish()
		return
	await scene_changed
	await process_frame
	_state.start_game()
	var layout := current_scene.get_node("Table/KernelLayout")
	var bank := layout.get_node("RolloverBank")
	var west := layout.get_node("BusLeft")
	var mid := layout.get_node("Boot")
	var east := layout.get_node("BusRight")
	var done := []
	bank.completed.connect(func(a): done.append(a))
	var base: int = _state.score

	west.lit = true
	bank.rotate_lit(1)
	_check(not west.lit and mid.lit and not east.lit, "rotar a la derecha mueve el encendido")
	bank.rotate_lit(1)
	bank.rotate_lit(1)
	_check(west.lit and not mid.lit and not east.lit, "la rotación da la vuelta")
	bank.rotate_lit(-1)
	_check(not west.lit and not mid.lit and east.lit, "rotar a la izquierda va al otro lado")

	# Los flippers (acciones) rotan: izquierda hacia la izquierda.
	Input.action_press(&"flipper_left")
	await physics_frame
	await physics_frame
	Input.action_release(&"flipper_left")
	_check(mid.lit and not east.lit, "flipper_left rota hacia la izquierda")
	Input.action_press(&"flipper_right")
	await physics_frame
	await physics_frame
	Input.action_release(&"flipper_right")
	_check(east.lit and not mid.lit, "flipper_right rota hacia la derecha")

	# Completar: se cruzan los dos que faltan.
	west.lit = true
	mid.lit = true
	east.lit = true
	mid.crossed.emit()
	await process_frame
	_check(done == [bank.award] and _state.score == base + bank.award, "al encender todos hay premio y señal")
	_check(_state.bonus_multiplier == 2, "se sube el multiplicador")
	_check(bank.lit_count() == 0, "los carriles se reinician")
	_finish()


func _check(ok: bool, label: String) -> bool:
	_checks += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		_failures += 1
	return ok


func _finish() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_scratch.path_join("records.cfg")))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_scratch))
	print("Rollovers: %d controles / %d fallos" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
