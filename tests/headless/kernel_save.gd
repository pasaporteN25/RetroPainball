extends SceneTree
## Kernel Panic: la partida guardada recuerda los procesos cargados y `sudo`, acepta guardados viejos
## (sin esas claves) y rechaza los inválidos. También revisa el tablero de procesos del arte.

const GameSave := preload("res://scripts/util/game_save.gd")
const PATH := "res://scenes/main.tscn"

var _game: Node
var _checks := 0
var _errors := 0
var _scratch := "user://test_kernel_save_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
var _table: Node
var _rules: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_game = root.get_node("GameState")
	_game.record_path = _scratch.path_join("records.cfg")
	_game.save_directory = _scratch
	_game.select_table("kernel_panic")
	if not _check(await _open(), "abre Kernel Panic"):
		_finish()
		return
	await create_timer(0.86).timeout
	var ball := _table.get_node("Balls").get_child(0) as RigidBody2D
	_move(ball, _table.to_global(Vector2(336, 1000)))
	ball.freeze = true

	# Un proceso cargado se guarda y se recupera.
	_rules._on_bank_completed(1000)
	current_scene.save_run()
	var saved := GameSave.load_run("kernel_panic", _scratch)
	_check(saved.get("kernel_processes", -1) == 1 and saved.get("kernel_sudo", true) == false, "el guardado lleva 1 proceso y sudo apagado")
	await _open()
	await process_frame
	_check(_rules.processes == 1 and not _rules.fork_ready and not _rules.multiball, "al reanudar queda 1 proceso cargado")
	_check(_art_processes() == 1, "el tablero de procesos muestra 1")

	# Con todos los procesos, FORK queda listo y el saucer encendido.
	_rules._on_bank_completed(1000)
	_check(_rules.fork_ready and _art_fork(), "con 2 procesos FORK queda listo y el tablero lo muestra")
	current_scene.save_run()
	await _open()
	await process_frame
	_check(_rules.processes == 2 and _rules.fork_ready and _table.get_node("KernelLayout/Fork").lit, "al reanudar FORK sigue listo y el saucer encendido")
	_check(_art_fork(), "el tablero muestra FORK listo")

	# En multibola: sudo encendido sobrevive a la reanudación.
	_rules.start_multiball()
	await process_frame
	_rules._set_sudo_lit(true)
	_check(_art_sudo() and _art_multiball(), "el tablero muestra SUDO y multibola")
	current_scene.save_run()
	saved = GameSave.load_run("kernel_panic", _scratch)
	_check(saved.get("kernel_sudo", false) == true and saved.balls.size() == 3, "el guardado lleva sudo encendido y 3 bolas")
	await _open()
	await process_frame
	_check(_rules.multiball and _rules.sudo_lit, "al reanudar sigue la multibola con sudo encendido")
	_check(_table.get_node("KernelLayout/Sudo").lit and _table.get_node("KernelLayout/Fork").lit, "spinner y saucer quedan encendidos")
	_check(_art_sudo(), "el tablero muestra SUDO tras reanudar")

	_test_validation(saved)
	_finish()


func _test_validation(saved: Dictionary) -> void:
	# Guardado viejo: sin claves de Kernel (con y sin extras) sigue siendo válido.
	var old := saved.duplicate()
	old.erase("kernel_processes")
	old.erase("kernel_sudo")
	_check(GameSave.save_run(old, _scratch) == OK and not GameSave.load_run("kernel_panic", _scratch).is_empty(), "un guardado sin claves de Kernel sigue siendo válido")
	var older := old.duplicate()
	for key in ["extra_balls", "extra_awarded", "kickback_ready"]:
		older.erase(key)
	_check(GameSave.save_run(older, _scratch) == OK, "un guardado sin extras ni Kernel sigue siendo válido")
	var one_key := saved.duplicate()
	one_key.erase("kernel_sudo")
	_check(GameSave.save_run(one_key, _scratch) == ERR_INVALID_DATA, "una sola clave de Kernel se rechaza")
	var bad := saved.duplicate()
	bad.kernel_processes = -1
	_check(GameSave.save_run(bad, _scratch) == ERR_INVALID_DATA, "procesos negativos se rechazan")
	bad.kernel_processes = 99
	_check(GameSave.save_run(bad, _scratch) == ERR_INVALID_DATA, "demasiados procesos se rechazan")
	bad = saved.duplicate()
	bad.kernel_sudo = 1
	_check(GameSave.save_run(bad, _scratch) == ERR_INVALID_DATA, "sudo que no es booleano se rechaza")
	bad = saved.duplicate()
	bad.table_id = "dracula"
	_check(GameSave.save_run(bad, _scratch) == ERR_INVALID_DATA, "las claves de Kernel no valen en otra mesa")
	# Restaurar un guardado viejo: no inventa estado.
	_rules.restore_state({})
	_check(_rules.processes == 0, "restore_state sin claves no inventa procesos")


func _open() -> bool:
	if change_scene_to_file(PATH) != OK:
		return false
	await scene_changed
	_table = current_scene.get_node("Table")
	_rules = _table.get_node("KernelRules")
	await process_frame
	return true


func _art_processes() -> int:
	return _table.get_node("PlayfieldArt")._processes


func _art_fork() -> bool:
	return _table.get_node("PlayfieldArt")._fork_ready


func _art_sudo() -> bool:
	return _table.get_node("PlayfieldArt")._sudo_lit


func _art_multiball() -> bool:
	return _table.get_node("PlayfieldArt")._multiball


func _check(ok: bool, description: String) -> bool:
	_checks += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", description])
	if not ok:
		_errors += 1
	return ok


func _finish() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_scratch.path_join("kernel_panic.save")))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_scratch.path_join("records.cfg")))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_scratch))
	print("Kernel Panic (guardado): %d controles / %d fallos" % [_checks, _errors])
	quit(0 if _errors == 0 else 1)


func _move(ball: RigidBody2D, at: Vector2) -> void:
	PhysicsServer2D.body_set_state(ball.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0, at))
	PhysicsServer2D.body_set_state(ball.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)
