extends SceneTree
## Reglas de Alicia: tamaño, naipes, madriguera con lock, gato de Cheshire, Té Loco y jackpot de la Tetera.
## Usa piezas y física reales con directorios descartables (S-09).

var _game: Node
var _checks := 0
var _errors := 0
var _scratch := "user://test_alice_rules_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
var _table: Node
var _rules: Node
var _messages: Array[String] = []
var _log := {"size": [], "cards": [], "completed": 0, "lit": [], "locked": [], "cheshire": [], "cheshire_hit": 0,
	"tea_started": 0, "tea_ended": 0}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_game = root.get_node("GameState")
	_game.record_path = _scratch.path_join("records.cfg")
	_game.save_directory = ""
	_game.message.connect(func(text: String) -> void: _messages.append(text))
	if not _check(change_scene_to_file("res://scenes/alicia.tscn") == OK, "abre Alicia"):
		_finish()
		return
	await scene_changed
	_table = current_scene.get_node("Table")
	_rules = _table.get_node("AliceRules")
	_rules.size_changed.connect(func(s: int) -> void: _log.size.append(s))
	_rules.card_flipped.connect(func(i: int, m: int) -> void: _log.cards.append([i, m]))
	_rules.cards_completed.connect(func() -> void: _log.completed += 1)
	_rules.lock_lit_changed.connect(func(l: bool) -> void: _log.lit.append(l))
	_rules.ball_locked.connect(func(n: int) -> void: _log.locked.append(n))
	_rules.cheshire_changed.connect(func(v: bool) -> void: _log.cheshire.append(v))
	_rules.cheshire_hit.connect(func() -> void: _log.cheshire_hit += 1)
	_rules.tea_party_started.connect(func() -> void: _log.tea_started += 1)
	_rules.tea_party_ended.connect(func() -> void: _log.tea_ended += 1)
	_check(_game.table_id == "alicia" and _game.high_score == 0, "Alicia tiene su propio récord")
	await create_timer(0.86).timeout
	var balls := _table.get_node("Balls")
	if not _check(balls.get_child_count() == 1 and _game.ball_in_lane, "sirve una bola en el carril"):
		_finish()
		return
	_check(_rules.size_state == 0 and _rules.cards_mask == 0 and not _rules.lock_lit and _rules.locked_balls == 0
		and not _rules.tea_party and _rules.cheshire_visible, "estado inicial de las reglas")
	var ball := balls.get_child(0) as RigidBody2D
	_move(ball, _table.to_global(Vector2(336, 1100)))
	ball.freeze = true

	_test_size()
	await _test_cards()
	await _test_cheshire()
	await _test_rabbithole_and_tea()
	await _test_ball_lost_and_reset()
	_finish()


func _test_size() -> void:
	var drink := _table.get_node("Size/DrinkMe")
	var eat := _table.get_node("Size/EatMe")
	var before: int = _game.score
	_messages.clear()
	drink.strike()
	_check(_rules.size_state == 1 and _game.score == before + 100 and _messages.back() == "CHICA", "BEBÉ-ME achica, paga 100 y avisa")
	_check(drink.active and not eat.active, "el blanco activo lo sabe")
	drink.strike()
	_check(_rules.size_state == 1 and _game.score == before + 100, "un rebote seguido contra el mismo blanco no lo alterna")
	_rules._on_size_target_hit(0)
	_check(_rules.size_state == 0 and _messages.back() == "TAMAÑO NORMAL" and not drink.active, "golpear el activo vuelve a NORMAL")
	_rules._on_size_target_hit(1)
	_check(_rules.size_state == 2 and _messages.back() == "GRANDE" and eat.active, "CÓMEME agranda")
	_rules._on_size_target_hit(0)
	_check(_rules.size_state == 1, "BEBÉ-ME desde GRANDE pasa a CHICA")
	_rules._on_size_target_hit(0)
	_check(_game.score == before + 100 * 5 and _log.size == [1, 0, 2, 1, 0], "size_changed avisa cada cambio y cada uno paga 100")


func _test_cards() -> void:
	var cards := _table.get_node("Cards").get_children()
	_check(cards.size() == 4, "el banco tiene cuatro naipes")
	var before: int = _game.score
	cards[0].strike()
	cards[0].strike()
	_check(_rules.cards_mask == 1 and cards[0].flipped and _game.score == before + 300, "golpear dos veces el mismo naipe lo da vuelta una vez (150 por golpe)")
	_check(_log.cards[0] == [0, 1], "card_flipped avisa índice y máscara")
	# GRANDE: paga doble y da vuelta el vecino apagado.
	_rules._on_size_target_hit(1)
	_check(_rules.size_state == 2, "tamaño GRANDE")
	before = _game.score
	cards[1].strike()
	_check(_game.score == before + 300, "con GRANDE cada naipe vale el doble")
	_check(_rules.cards_mask == 0b0111 and cards[2].flipped, "con GRANDE da vuelta el vecino apagado")
	var multiplier: int = _game.bonus_multiplier
	before = _game.score
	_messages.clear()
	cards[3].strike()
	_check(_game.score == before + 300 + 1000, "completar el banco paga 1.000 además del golpe")
	_check(_game.bonus_multiplier == multiplier + 1 and _messages.has("NAIPES COMPLETOS"), "completar sube el multiplicador y avisa")
	_check(_log.completed == 1 and _rules.cards_mask == 0 and not cards[0].flipped and not cards[3].flipped, "el banco se reinicia")
	_check(_rules.lock_lit and _table.get_node("Rabbithole").lock_lit and _messages.has("LOCK ENCENDIDO"), "completar el banco enciende LOCK")
	_check(not _table.get_node("Rabbithole").lock_armed, "con GRANDE la madriguera todavía no encierra")
	_rules._on_size_target_hit(1)
	_check(_rules.size_state == 0, "vuelve a NORMAL")


func _test_cheshire() -> void:
	var cheshire := _table.get_node("Cheshire")
	var shape := cheshire.get_node("Shape") as CollisionShape2D
	_rules.reset()
	_game.start_game()
	await process_frame
	_log.cheshire.clear()
	_check(_rules.cheshire_visible and not shape.disabled, "el gato empieza visible y golpeable")
	_rules.tick(3.9)
	_check(_rules.cheshire_visible, "sigue visible antes de los 4 s")
	_rules.tick(0.2)
	await process_frame
	await process_frame
	_check(not _rules.cheshire_visible and shape.disabled and _log.cheshire == [false], "a los 4 s se vuelve invisible y la bola lo atraviesa")
	var before: int = _game.score
	_rules._on_cheshire_struck(Vector2.ZERO)
	_check(_game.score == before and _log.cheshire_hit == 0, "invisible no puntúa")
	_rules.tick(2.9)
	_check(not _rules.cheshire_visible, "sigue invisible antes de los 3 s")
	_rules.tick(0.2)
	await process_frame
	await process_frame
	_check(_rules.cheshire_visible and not shape.disabled and _log.cheshire == [false, true], "a los 3 s vuelve a aparecer")
	_rules.tick(3.0)
	before = _game.score
	_rules._on_cheshire_struck(Vector2.ZERO)
	_check(_game.score == before + 1500 and _log.cheshire_hit == 1, "golpearlo visible paga 1.500")
	_rules.tick(3.9)
	_check(_rules.cheshire_visible, "el golpe lo mantiene visible 4 s más")
	_rules._on_cheshire_struck(Vector2.ZERO)
	_rules.tick(0.2)
	_check(not _rules.cheshire_visible, "la extensión vale una sola vez por ciclo")
	_rules.tick(3.1)
	_check(_rules.cheshire_visible, "y el ciclo sigue")
	# Fuera de la bola: el dibujo se desvanece sin saltos.
	cheshire.set_shown(false)
	cheshire._process(0.1)
	_check(cheshire.visibility > 0.0 and cheshire.visibility < 1.0, "el gato se desvanece de a poco")
	cheshire.set_shown(true)


func _test_rabbithole_and_tea() -> void:
	var hole := _table.get_node("Rabbithole") as Area2D
	var teapot := _table.get_node("Teapot")
	var cards := _table.get_node("Cards").get_children()
	var balls := _table.get_node("Balls")
	_rules.reset()
	_log.locked.clear()
	_game.start_game()
	await create_timer(0.85).timeout
	var ball := balls.get_child(0) as RigidBody2D
	# Sin LOCK: retiene 1 s y devuelve con 300.
	_move(ball, _table.to_global(Vector2(336, 1100)))
	await create_timer(0.05).timeout
	var before: int = _game.score
	_move(ball, hole.global_position, Vector2(0, 100))
	await create_timer(0.5).timeout
	_check(ball.freeze and _game.score == before, "la madriguera retiene la bola")
	await create_timer(0.7).timeout
	_check(not ball.freeze and _game.score >= before + 300, "y la devuelve con 300 puntos tras 1 s")
	await create_timer(0.1).timeout
	_check(ball.global_position.y > hole.global_position.y, "sale hacia abajo y no se vuelve a capturar enseguida")
	_move(ball, _table.to_global(Vector2(336, 1100)))
	await create_timer(0.05).timeout
	# LOCK encendido pero tamaño NORMAL: solo retiene y devuelve.
	for card in cards:
		card.strike()
	_check(_rules.lock_lit and not hole.lock_armed, "LOCK encendido, pero con tamaño NORMAL no encierra")
	_move(ball, hole.global_position, Vector2(0, 100))
	await create_timer(0.3).timeout
	_check(ball.freeze and not ball.has_meta(&"alice_locked") and _rules.locked_balls == 0, "con tamaño NORMAL solo retiene")
	await create_timer(0.9).timeout
	_move(ball, _table.to_global(Vector2(336, 1100)))
	await create_timer(0.05).timeout
	# CHICA + LOCK: encierra.
	_rules._on_size_target_hit(0)
	_check(hole.lock_armed, "CHICA con LOCK arma la madriguera")
	before = _game.score
	var lives: int = _game.balls_left
	_move(ball, hole.global_position, Vector2(0, 100))
	await create_timer(0.15).timeout
	_check(ball.freeze and ball.has_meta(&"alice_locked") and _rules.locked_balls == 1, "con CHICA y LOCK la bola queda encerrada")
	_check(_game.score == before + 500 and not _rules.lock_lit and not hole.lock_armed, "encerrar paga 500 y apaga LOCK")
	_check(balls.get_child_count() == 2 and _game.ball_in_lane, "sale una bola nueva al carril")
	_check(_messages.has("BOLA ENCERRADA"), "avisa BOLA ENCERRADA")
	# La bola libre se pierde: la encerrada cuenta como bola en juego y se la libera.
	var free: RigidBody2D = null
	for b in balls.get_children():
		if b != ball:
			free = b
	_move(free, _table.to_global(Vector2(336, 1500)))
	await create_timer(0.3).timeout
	_check(_game.balls_left == lives, "drenar la bola libre con una encerrada no gasta turno")
	await create_timer(0.1).timeout
	_check(_rules.locked_balls == 0 and not ball.freeze and not ball.has_meta(&"alice_locked") and balls.get_child_count() == 1,
		"si solo quedan encerradas, se las libera")
	_move(ball, _table.to_global(Vector2(336, 1100)))
	await create_timer(0.05).timeout
	# Dos encierros: Té Loco.
	_log.locked.clear()
	_rules._on_size_target_hit(0)
	if _rules.size_state != 1:
		_rules._on_size_target_hit(0)
	for round in 2:
		if _rules.size_state != 1:
			_rules._on_size_target_hit(0)
		for card in cards:
			card.strike()
		_check(_rules.lock_lit, "ronda %d: el banco enciende LOCK" % [round + 1])
		var live: RigidBody2D = null
		for b in balls.get_children():
			if not b.is_queued_for_deletion() and not b.has_meta(&"alice_locked"):
				live = b
		_move(live, hole.global_position, Vector2(0, 100))
		await create_timer(0.2).timeout
		if round == 0:
			_check(_rules.locked_balls == 1 and not _rules.tea_party and balls.get_child_count() == 2, "una bola encerrada todavía no es Té Loco")
	_check(_rules.tea_party and _log.tea_started == 1 and _log.locked == [1, 2, 0], "con 2 bolas encerradas empieza Té Loco")
	_check(balls.get_child_count() == 3 and _rules.locked_balls == 0 and _messages.has("¡TÉ LOCO!"), "Té Loco: se liberan las 2 bolas y hay 3 en juego")
	_check(teapot.jackpot_ready, "la tetera se enciende")
	_rules.tick(10.0)
	_check(_rules.cheshire_visible, "durante Té Loco el gato queda siempre visible")
	var all := balls.get_children()
	_move(all[0], _table.to_global(Vector2(300, 1000)))
	_move(all[1], _table.to_global(Vector2(380, 1000)))
	before = _game.score
	_move(all[2], teapot.global_position + Vector2(0, -52), Vector2(0, 700))
	await create_timer(0.12).timeout
	_check(_game.score == before + 5000, "en Té Loco la tetera paga 5.000")
	_move(all[1], _table.to_global(Vector2(380, 1500)))
	_move(all[2], _table.to_global(Vector2(420, 1500)))
	await create_timer(0.3).timeout
	_check(_game.balls_left == lives and balls.get_child_count() == 1, "drenar bolas de multibola no gasta turno")
	_check(not _rules.tea_party and _log.tea_ended == 1 and not teapot.jackpot_ready, "con una sola bola termina Té Loco")
	before = _game.score
	_rules._on_teapot_struck(teapot.global_position)
	_check(_game.score == before + 250, "fuera de Té Loco la tetera paga solo 250")


func _test_ball_lost_and_reset() -> void:
	var balls := _table.get_node("Balls")
	_rules._on_size_target_hit(1)
	_check(_rules.size_state == 2, "tamaño GRANDE antes de perder la bola")
	var lives: int = _game.balls_left
	var ball := balls.get_child(0) as RigidBody2D
	_move(ball, _table.to_global(Vector2(336, 1500)))
	await create_timer(0.3).timeout
	_check(_game.balls_left == lives - 1 and _rules.size_state == 0, "perder la bola vuelve el tamaño a NORMAL")
	_rules._on_size_target_hit(0)
	_table.get_node("Cards").get_child(0).strike()
	_game.start_game()
	await create_timer(0.8).timeout
	_check(_rules.size_state == 0 and _rules.cards_mask == 0 and not _rules.lock_lit and _rules.locked_balls == 0 and not _rules.tea_party
		and _rules.cheshire_visible, "reiniciar la partida limpia las reglas")
	_check(balls.get_child_count() == 1 and _game.bonus_multiplier == 1, "y sirve una sola bola con multiplicador 1")


func _check(ok: bool, description: String) -> bool:
	_checks += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", description])
	if not ok:
		_errors += 1
	return ok


func _finish() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_scratch))
	print("Alicia (reglas): %d controles / %d fallos" % [_checks, _errors])
	quit(0 if _errors == 0 else 1)


func _move(ball: RigidBody2D, at: Vector2, velocity := Vector2.ZERO) -> void:
	PhysicsServer2D.body_set_state(ball.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0, at))
	PhysicsServer2D.body_set_state(ball.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, velocity)
