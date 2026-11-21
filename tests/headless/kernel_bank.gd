extends SceneTree
## G-06: el banco de blancos de Kernel Panic recuerda los golpes, premia y se reinicia.

const SCENE := "res://scenes/main.tscn"
var _state: Node
var _checks := 0
var _failures := 0
var _scratch := "user://test_kernel_bank_%d" % OS.get_process_id()


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
	var bank := layout.get_node("StandupBank")
	var left := layout.get_node("StandupLeft")
	var right := layout.get_node("StandupRight")
	var done := []
	bank.completed.connect(func(a): done.append(a))
	var base: int = _state.score
	_check(bank.hit_count() == 0 and not left.activated, "el banco arranca vacío")
	left.hit.emit()  # no activa por sí solo: lo hace on_ball_contact
	_check(done.is_empty(), "una señal suelta no completa el banco")
	left.set_activated(true)
	_check(bank.hit_count() == 1 and done.is_empty(), "un blanco activado no completa el banco")
	right.activated = true
	right.hit.emit()
	await process_frame
	_check(done == [bank.award], "al activar todos el banco emite completed")
	_check(_state.score == base + bank.award, "el banco otorga su premio")
	_check(_state.bonus_multiplier == 2, "el banco sube el multiplicador")
	_check(bank.hit_count() == 0 and not left.activated and not right.activated, "el banco se reinicia al completarse")
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
	print("Banco de blancos: %d controles / %d fallos" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
