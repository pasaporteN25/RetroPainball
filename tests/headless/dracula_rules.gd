extends SceneTree
## Reglas de Drácula: banco de murciélagos, Carfax, ataúd con lock, Medianoche, jackpot del retrato
## y que las bolas encerradas no gasten la bola. Usa piezas y física reales con directorios descartables.

var _game: Node
var _checks := 0
var _errors := 0
var _scratch := "user://test_dracula_rules_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
var _table: Node
var _rules: Node
var _log := {"midnight_started": 0, "midnight_ended": 0, "locked": [], "carfax": [], "bats": [], "lit": []}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_game = root.get_node("GameState")
	_game.record_path = _scratch.path_join("records.cfg")
	_game.save_directory = ""
	if not _check(change_scene_to_file("res://scenes/dracula.tscn") == OK, "abre Drácula"):
		_finish()
		return
	await scene_changed
	_table = current_scene.get_node("Table")
	_rules = _table.get_node("DraculaRules")
	_rules.midnight_started.connect(func() -> void: _log.midnight_started += 1)
	_rules.midnight_ended.connect(func() -> void: _log.midnight_ended += 1)
	_rules.ball_locked.connect(func(n: int) -> void: _log.locked.append(n))
	_rules.carfax_scored.connect(func(s: int) -> void: _log.carfax.append(s))
	_rules.bats_changed.connect(func(n: int) -> void: _log.bats.append(n))
	_rules.lock_lit_changed.connect(func(l: bool) -> void: _log.lit.append(l))
	_check(_game.table_id == "dracula" and _game.high_score == 0, "Drácula tiene su propio récord")
	await create_timer(0.86).timeout
	var balls := _table.get_node("Balls")
	if not _check(balls.get_child_count() == 1 and _game.ball_in_lane, "sirve una bola en el carril"):
		_finish()
		return
	var ball := balls.get_child(0) as RigidBody2D

	await _test_bats()
	await _test_carfax(ball)
	await _test_lock_and_drain(ball)
	await _test_midnight()
	_finish()


func _test_bats() -> void:
	var bats := _table.get_node("Bats").get_children()
	_check(bats.size() == 3, "el banco tiene tres murciélagos")
	var before: int = _game.score
	bats[0].strike()
	bats[0].strike()
	_check(_rules.bats_hit == 1 and bats[0].activated, "golpear dos veces el mismo murciélago cuenta una vez")
	bats[1].strike()
	_check(_rules.bats_hit == 2 and not _rules.locks_lit, "con dos murciélagos todavía no hay premio")
	bats[2].strike()
	_check(_game.score == before + 4 * 150 + 1000, "el banco paga 1.000 además de los golpes")
	_check(_game.bonus_multiplier == 2, "completar el banco sube el multiplicador")
	_check(_rules.locks_lit and _table.get_node("Coffin").lock_lit, "completar el banco enciende LOCK")
	_check(_rules.bats_hit == 0 and not bats[0].activated and not bats[2].activated, "el banco se reinicia")
	_check(_log.bats == [1, 2, 3, 0] or _log.bats == [1, 1, 2, 3, 0], "bats_changed avisa cada golpe y el reinicio")


func _test_carfax(ball: RigidBody2D) -> void:
	var gate_in := _table.get_node("Carfax/GateIn") as Node2D
	var gate_out := _table.get_node("Carfax/GateOut") as Node2D
	var before: int = _game.score
	# Al revés (salida y después entrada) no cuenta.
	_move(ball, gate_out.global_position, Vector2(0, 400))
	await create_timer(0.1).timeout
	_move(ball, gate_in.global_position, Vector2(0, 400))
	await create_timer(0.1).timeout
	_check(_game.score == before and _log.carfax.is_empty(), "cruzar Carfax al revés no puntúa")
	# Fuera de tiempo: la entrada ya se registró arriba; esperar más de 3 s la vence.
	_move(ball, _table.to_global(Vector2(336, 900)))
	ball.freeze = true
	await create_timer(3.2).timeout
	ball.freeze = false
	_move(ball, gate_out.global_position, Vector2(0, 400))
	await create_timer(0.1).timeout
	_check(_game.score == before and _log.carfax.is_empty(), "salir de Carfax pasados 3 s no puntúa")
	# En orden: 500, 1000, 1500 y multiplicador en la tercera.
	var expected := [500, 1000, 1500]
	for lap in 3:
		before = _game.score
		_move(ball, gate_in.global_position, Vector2(0, 400))
		await create_timer(0.1).timeout
		_move(ball, gate_out.global_position, Vector2(0, 400))
		await create_timer(0.1).timeout
		_check(_game.score == before + expected[lap], "vuelta %d de Carfax paga %d" % [lap + 1, expected[lap]])
	_check(_log.carfax == [0, 1, 2], "carfax_scored avisa 0, 1 y 2")
	_check(_game.bonus_multiplier == 3 and _rules.carfax_stage == 0, "la tercera vuelta sube el multiplicador y reinicia la cuenta")
	_move(ball, _table.to_global(Vector2(336, 1000)), Vector2.ZERO)


func _test_lock_and_drain(ball: RigidBody2D) -> void:
	var coffin := _table.get_node("Coffin") as Area2D
	var balls := _table.get_node("Balls")
	var lives: int = _game.balls_left
	var before: int = _game.score
	_check(_rules.locks_lit, "LOCK sigue encendido para el ataúd")
	_move(ball, coffin.global_position, Vector2(0, 200))
	await create_timer(0.15).timeout
	_check(ball.freeze and ball.has_meta(&"dracula_locked") and _rules.locked_balls == 1, "con LOCK la bola queda encerrada y congelada")
	_check(_game.score == before + 500 and not _rules.locks_lit, "encerrar paga 500 y apaga LOCK")
	_check(balls.get_child_count() == 2 and _game.ball_in_lane, "sale una bola nueva al carril")
	await create_timer(0.8).timeout
	_check(ball.freeze and ball.global_position.distance_to(coffin.global_position) < 20.0, "la bola encerrada sigue ahí")
	# La bola libre se pierde: la bola encerrada cuenta como bola en juego y no se pierde turno.
	var free: RigidBody2D = null
	for b in balls.get_children():
		if b != ball:
			free = b
	_move(free, _table.to_global(Vector2(336, 1500)))
	await create_timer(0.3).timeout
	_check(_game.balls_left == lives, "drenar la bola libre con una encerrada no gasta turno")
	await create_timer(0.1).timeout
	_check(_rules.locked_balls == 0 and not ball.freeze and not ball.has_meta(&"dracula_locked"), "si solo quedan encerradas, se las libera")
	_check(_rules.locked_balls == 0 and balls.get_child_count() == 1, "queda una única bola libre")
	# Baja de los flippers para que el ataúd la vuelva a armar.
	_move(ball, _table.to_global(Vector2(336, 1100)), Vector2.ZERO)
	await create_timer(0.05).timeout
	# Sin LOCK el ataúd retiene 0,6 s y devuelve con 300.
	before = _game.score
	_move(ball, coffin.global_position, Vector2(0, 200))
	await create_timer(0.3).timeout
	_check(ball.freeze and _game.score == before, "sin LOCK el ataúd retiene la bola un instante")
	await create_timer(0.35).timeout
	_check(not ball.freeze and _game.score == before + 300, "y la devuelve con 300 puntos")
	await create_timer(0.1).timeout
	_check(not ball.freeze and ball.global_position.distance_to(coffin.global_position) > 20.0, "anti-recaptura: no vuelve a entrar enseguida")
	# Baja de los flippers para que el ataúd la vuelva a armar.
	_move(ball, _table.to_global(Vector2(336, 1100)), Vector2.ZERO)
	await create_timer(0.05).timeout


func _test_midnight() -> void:
	var coffin := _table.get_node("Coffin") as Area2D
	var balls := _table.get_node("Balls")
	var portrait := _table.get_node("Portrait") as Node2D
	var bats := _table.get_node("Bats").get_children()
	var lives: int = _game.balls_left
	_log.locked.clear()
	for round in 2:
		for bat in bats:
			bat.strike()
		_check(_rules.locks_lit, "ronda %d: el banco enciende LOCK" % [round + 1])
		var ball := _live_ball(balls, coffin)
		_move(ball, coffin.global_position, Vector2(0, 200))
		await create_timer(0.2).timeout
		if round == 0:
			_check(_rules.locked_balls == 1 and not _rules.midnight and balls.get_child_count() == 2, "una bola encerrada todavía no es Medianoche")
	_check(_rules.midnight and _log.midnight_started == 1 and _log.locked == [1, 2, 0], "con 2 bolas encerradas empieza la Medianoche")
	_check(balls.get_child_count() == 3 and _rules.locked_balls == 0, "Medianoche: se liberan las 2 bolas y hay 3 en juego")
	_check(portrait.jackpot_ready, "el retrato se enciende")
	# Dejar las bolas en lugares seguros y golpear el retrato.
	var all := balls.get_children()
	_move(all[0], _table.to_global(Vector2(300, 1000)), Vector2.ZERO)
	_move(all[1], _table.to_global(Vector2(380, 1000)), Vector2.ZERO)
	var before: int = _game.score
	_move(all[2], portrait.global_position + Vector2(0, -52), Vector2(0, 700))
	await create_timer(0.12).timeout
	_check(_game.score == before + 5000, "en Medianoche el retrato paga 5.000")
	# Termina cuando queda una sola bola.
	_move(all[1], _table.to_global(Vector2(380, 1500)))
	_move(all[2], _table.to_global(Vector2(420, 1500)))
	await create_timer(0.3).timeout
	_check(_game.balls_left == lives and balls.get_child_count() == 1, "drenar bolas de multibola no gasta turno")
	_check(not _rules.midnight and _log.midnight_ended == 1 and not portrait.jackpot_ready, "con una sola bola termina la Medianoche")
	before = _game.score
	_rules._on_portrait_struck(portrait.global_position)
	_check(_game.score == before + 250, "fuera de Medianoche el retrato paga solo 250")
	# Reinicio: todo en cero.
	_game.start_game()
	await create_timer(0.8).timeout
	_check(not _rules.locks_lit and _rules.locked_balls == 0 and _rules.bats_hit == 0 and _rules.carfax_stage == 0 and not _rules.midnight,
		"reiniciar la partida limpia las reglas")
	_check(balls.get_child_count() == 1 and _game.bonus_multiplier == 1, "y sirve una sola bola con multiplicador 1")


## Una bola libre (no encerrada) para llevarla al ataúd.
func _live_ball(balls: Node, _coffin: Node) -> RigidBody2D:
	for b in balls.get_children():
		if not b.is_queued_for_deletion() and not b.has_meta(&"dracula_locked"):
			return b
	return null


func _check(ok: bool, description: String) -> bool:
	_checks += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", description])
	if not ok:
		_errors += 1
	return ok


func _finish() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_scratch))
	print("Drácula (reglas): %d controles / %d fallos" % [_checks, _errors])
	quit(0 if _errors == 0 else 1)


func _move(ball: RigidBody2D, at: Vector2, velocity := Vector2.ZERO) -> void:
	PhysicsServer2D.body_set_state(ball.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0, at))
	PhysicsServer2D.body_set_state(ball.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, velocity)
