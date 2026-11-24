extends SceneTree
## Kernel Panic (S-05): procesos, saucer FORK que retiene la bola (bloqueo), fork() en tres bolas,
## jackpot sudo con el spinner, fin de la multibola y guardado/continuación en medio de la multibola.
## Usa piezas y física reales con directorios descartables.

const GameSave := preload("res://scripts/util/game_save.gd")
const PATH := "res://scenes/main.tscn"

var _game: Node
var _checks := 0
var _errors := 0
var _scratch := "user://test_kernel_multiball_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
var _table: Node
var _rules: Node
var _log := {"started": 0, "ended": 0, "jackpots": [], "processes": [], "fork": []}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_game = root.get_node("GameState")
	_game.record_path = _scratch.path_join("records.cfg")
	_game.save_directory = _scratch
	_game.select_table("kernel_panic")
	if not _check(change_scene_to_file(PATH) == OK, "abre Kernel Panic"):
		_finish()
		return
	await scene_changed
	_bind()
	await create_timer(0.86).timeout
	var balls := _table.get_node("Balls")
	if not _check(balls.get_child_count() == 1 and _game.ball_in_lane, "sirve una bola en el carril"):
		_finish()
		return
	_check(_rules != null and not _rules.multiball and not _rules.fork_ready, "arranca sin multibola ni fork listo")
	var ball := balls.get_child(0) as RigidBody2D
	_move(ball, _table.to_global(Vector2(336, 1000)), Vector2.ZERO)
	ball.freeze = true

	await _test_no_fork_without_processes(ball)
	await _test_processes()
	await _test_fork_lock(ball)
	await _test_sudo()
	await _test_save_resume()
	_finish()


func _bind() -> void:
	_table = current_scene.get_node("Table")
	_rules = _table.get_node("KernelRules")
	_log = {"started": 0, "ended": 0, "jackpots": [], "processes": [], "fork": []}
	_rules.multiball_started.connect(func() -> void: _log.started += 1)
	_rules.multiball_ended.connect(func() -> void: _log.ended += 1)
	_rules.jackpot_scored.connect(func(a: int) -> void: _log.jackpots.append(a))
	_rules.process_loaded.connect(func(c: int, _t: int) -> void: _log.processes.append(c))
	_rules.fork_ready_changed.connect(func(r: bool) -> void: _log.fork.append(r))


func _test_no_fork_without_processes(ball: RigidBody2D) -> void:
	var saucer := _table.get_node("KernelLayout/Fork")
	var before: int = _game.score
	ball.freeze = false
	_move(ball, saucer.global_position, Vector2(0, 200))
	await create_timer(0.15).timeout
	_check(saucer.is_holding() and ball.freeze, "el saucer retiene la bola (bloqueo)")
	await create_timer(0.8).timeout
	_check(not saucer.is_holding() and not ball.freeze, "y la devuelve")
	_check(_game.score >= before + 500, "entrar al saucer paga al menos sus 500")
	_check(not _rules.multiball and _table.get_node("Balls").get_child_count() == 1, "sin procesos no hay fork()")
	_move(ball, _table.to_global(Vector2(336, 1000)), Vector2.ZERO)
	ball.freeze = true


func _test_processes() -> void:
	var layout := _table.get_node("KernelLayout")
	for target in layout.get_node("StandupBank")._targets:
		target.set_activated(true)
	layout.get_node("StandupLeft").hit.emit()
	await process_frame
	_check(_rules.processes == 1 and not _rules.fork_ready and _log.processes == [1], "completar el banco carga un proceso")
	var lanes: Array = layout.get_node("RolloverBank")._lanes
	for lane in lanes:
		lane.set_lit(true)
	lanes[0].crossed.emit()
	await process_frame
	_check(_rules.processes == 2 and _rules.fork_ready and _log.fork == [true], "completar los rollovers carga el segundo y habilita fork()")
	_check(layout.get_node("Fork").lit, "el saucer se enciende")


func _test_fork_lock(ball: RigidBody2D) -> void:
	var saucer := _table.get_node("KernelLayout/Fork")
	var balls := _table.get_node("Balls")
	ball.freeze = false
	_move(ball, saucer.global_position, Vector2(0, 200))
	await create_timer(0.15).timeout
	_check(saucer.is_holding() and ball.freeze and not _rules.multiball, "con fork listo la bola queda retenida antes de bifurcarse")
	await create_timer(0.8).timeout
	_check(_rules.multiball and _log.started == 1, "al salir del saucer empieza la multibola")
	_check(balls.get_child_count() == 3, "fork() deja tres bolas en juego")
	_check(not _rules.fork_ready and _rules.processes == 0 and not saucer.lit, "se consumen los procesos y se apaga el saucer")
	# Dejar las bolas quietas en un lugar seguro para que no se drenen mientras se prueba.
	for b in balls.get_children():
		_move(b, _table.to_global(Vector2(300 + 40 * b.get_index(), 1000)), Vector2.ZERO)
		b.freeze = true


func _test_sudo() -> void:
	var saucer := _table.get_node("KernelLayout/Fork")
	var spinner := _table.get_node("KernelLayout/Sudo")
	var balls := _table.get_node("Balls")
	var free := balls.get_child(0) as RigidBody2D
	# Sin sudo encendido, entrar al saucer solo paga el saucer.
	var before: int = _game.score
	free.freeze = false
	_move(free, saucer.global_position, Vector2(0, 200))
	await create_timer(1.0).timeout
	_check(_game.score >= before + 500 and _log.jackpots.is_empty() and _game.jackpots == 0, "sin sudo el saucer no paga jackpot")
	_check(not _rules.sudo_lit, "sudo empieza apagado")
	# La bola queda quieta mientras gira el spinner, así no vuelve a entrar al saucer antes de tiempo.
	_move(free, _table.to_global(Vector2(336, 1000)), Vector2.ZERO)
	free.freeze = true
	# El spinner, empujado fuerte y seguido, enciende sudo.
	for i in 8:
		spinner.kick_spin(Vector2(0, -900))
		await create_timer(1.0).timeout
		if _rules.sudo_lit:
			break
	_check(_rules.sudo_lit and spinner.lit and saucer.lit, "girar el spinner enciende sudo")
	free.freeze = false
	before = _game.score
	_move(free, saucer.global_position, Vector2(0, 200))
	await create_timer(1.0).timeout
	_check(_log.jackpots == [5000] and _game.jackpots == 1, "con sudo el saucer paga el jackpot y lo cuenta en las estadísticas")
	_check(_game.score >= before + 5500, "el jackpot suma 5.000 además del saucer")
	_check(not _rules.sudo_lit and not spinner.lit and _rules.multiball, "después del jackpot sudo se apaga y sigue la multibola")
	_move(free, _table.to_global(Vector2(300, 1000)), Vector2.ZERO)
	free.freeze = true


func _test_save_resume() -> void:
	var balls := _table.get_node("Balls")
	var score: int = _game.score
	current_scene.save_run()
	var saved := GameSave.load_run("kernel_panic", _scratch)
	_check(not saved.is_empty() and saved.score == score, "se guarda la partida en medio de la multibola")
	_check(saved.get("balls", []).size() == 3, "se guardan las tres bolas")
	if not _check(change_scene_to_file(PATH) == OK, "reabre Kernel Panic"):
		return
	await scene_changed
	_bind()
	await process_frame
	balls = _table.get_node("Balls")
	_check(balls.get_child_count() == 3 and _game.score == score, "la restauración devuelve puntaje y las tres bolas")
	_check(_rules.multiball, "la multibola continúa al reanudar")
	# Fin de la multibola: quedan dos bolas drenadas y una sola en juego.
	await create_timer(0.1).timeout
	var lives: int = _game.balls_left
	var all := balls.get_children()
	_move(all[1], _table.to_global(Vector2(300, 1500)))
	_move(all[2], _table.to_global(Vector2(380, 1500)))
	await create_timer(0.4).timeout
	_check(balls.get_child_count() == 1 and _game.balls_left == lives, "drenar bolas de multibola no gasta turno")
	_check(not _rules.multiball and _log.ended == 1, "con una sola bola termina la multibola")
	_check(not _rules.sudo_lit and not _rules.fork_ready, "y no queda nada encendido")
	# Una partida nueva deja las reglas en cero.
	_game.start_game()
	await create_timer(0.8).timeout
	_check(not _rules.multiball and _rules.processes == 0 and balls.get_child_count() == 1, "reiniciar la partida limpia las reglas")


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
	print("Kernel Panic (multibola): %d controles / %d fallos" % [_checks, _errors])
	quit(0 if _errors == 0 else 1)


func _move(ball: RigidBody2D, at: Vector2, velocity := Vector2.ZERO) -> void:
	PhysicsServer2D.body_set_state(ball.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0, at))
	PhysicsServer2D.body_set_state(ball.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, velocity)
