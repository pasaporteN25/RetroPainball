extends SceneTree
## G-04: nudge/tilt. Calor, aviso, TILT (flippers muertos, sin bonus) y vuelta a la normalidad.

const Tilt := preload("res://scripts/table/tilt.gd")
const PATH := "res://scenes/main.tscn"
var _game: Node
var _checks := 0
var _errors := 0
var _scratch := "user://test_tilt_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_pure_logic()
	_game = root.get_node("GameState")
	_game.record_path = _scratch.path_join("records.cfg")
	_game.save_directory = ""
	_check(InputMap.has_action("nudge"), "existe la acción de teclado nudge")
	_game_rules()
	await _scene()
	_finish()


func _pure_logic() -> void:
	var t := Tilt.new()
	_check(t.register_nudge() == Tilt.Result.NUDGE, "el primer empujón es limpio")
	_check(t.register_nudge() == Tilt.Result.IGNORED, "un segundo empujón dentro del enfriamiento se ignora")
	t.tick(t.nudge_cooldown)
	_check(t.register_nudge() == Tilt.Result.WARNING, "con calor medio hay aviso")
	t.tick(t.nudge_cooldown)
	_check(t.register_nudge() == Tilt.Result.WARNING and not t.tilted, "sigue avisando sin llegar a TILT")
	t.tick(t.nudge_cooldown)
	_check(t.register_nudge() == Tilt.Result.TILT and t.tilted, "con calor alto es TILT")
	t.tick(10.0)
	_check(t.register_nudge() == Tilt.Result.IGNORED and t.heat == 0.0, "en TILT no hay más empujones aunque el calor decaiga")
	t.reset()
	_check(not t.tilted and t.register_nudge() == Tilt.Result.NUDGE, "reset vuelve a la normalidad")
	var cool := Tilt.new()
	cool.register_nudge()
	cool.tick(10.0)
	_check(cool.heat == 0.0, "el calor decae con el tiempo")
	var shake := Tilt.new()
	_check(not shake.feed_accelerometer(Vector3(0, 9.8, 0)), "la primera lectura solo calibra")
	_check(not shake.feed_accelerometer(Vector3(0.2, 9.7, 0.1)), "un teléfono quieto no es sacudida")
	_check(shake.feed_accelerometer(Vector3(15, 9.8, 5)), "un golpe brusco es sacudida")
	_check(not Tilt.new().feed_accelerometer(Vector3.ZERO), "sin acelerómetro (PC) no hay sacudida")


func _game_rules() -> void:
	_game.start_game()
	var pushes := [0]
	_game.nudged.connect(func(_d): pushes[0] += 1)
	_game.add_score(2000, Vector2.ZERO)
	_game.nudge(Vector2.UP)
	_check(pushes[0] == 1 and not _game.tilted, "un nudge empuja y no hace TILT")
	for i in 6:
		_game.tilt.tick(1.0)  # enfría el enfriamiento pero no el calor entero
		_game.tilt.heat = 0.9
		_game.tilt._cooldown = 0.0
	_game.nudge(Vector2.UP)
	_check(_game.tilted, "calor alto: TILT")
	var score_before: int = _game.score
	var balls_before: int = _game.balls_left
	_game.lose_ball()
	_check(_game.score == score_before and _game.last_bonus_award == 0, "en TILT el bonus se pierde")
	_check(not _game.tilted and _game.balls_left == balls_before - 1, "la bola siguiente vuelve a la normalidad")
	_game.add_score(2000, Vector2.ZERO)
	var before: int = _game.score
	_game.lose_ball()
	_check(_game.score == before + 200, "sin TILT el bonus se cobra normal")
	_game.leave_game()


func _scene() -> void:
	_check(change_scene_to_file(PATH) == OK, "abre Kernel Panic")
	await scene_changed
	await create_timer(0.8).timeout
	var table := current_scene.get_node("Table")
	var ball := table.get_node("Balls").get_child(0) as RigidBody2D
	# Bola en el aire a una velocidad conocida, sin gravedad.
	ball.gravity_scale = 0.0
	_move(ball, table.to_global(Vector2(336, 600)), Vector2.ZERO)
	await physics_frame
	_game.nudge(Vector2.UP)
	await physics_frame
	_check(ball.linear_velocity.y < -100.0, "el nudge le da un empujón hacia arriba a la bola")
	# Los flippers no responden en TILT.
	var flipper: Node2D = _find_flipper(table)
	_game.tilt.tilted = true
	var rest: float = flipper.rotation
	Input.action_press("flipper_left")
	Input.action_press("flipper_right")
	await create_timer(0.4).timeout
	_check(is_equal_approx(flipper.rotation, rest), "en TILT el flipper no sube")
	_game.tilt.reset()
	await create_timer(0.4).timeout
	_check(not is_equal_approx(flipper.rotation, rest), "fuera de TILT el flipper responde")
	Input.action_release("flipper_left")
	Input.action_release("flipper_right")


func _find_flipper(node: Node) -> Node2D:
	for child in node.find_children("*", "AnimatableBody2D", true, false):
		if child.get("side") == 0:
			return child
	return null


func _finish() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_scratch))
	print("Tilt: %d controles / %d fallos" % [_checks, _errors])
	quit(0 if _errors == 0 else 1)


func _check(ok: bool, label: String) -> bool:
	_checks += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		_errors += 1
	return ok


func _move(ball: RigidBody2D, at: Vector2, velocity: Vector2) -> void:
	PhysicsServer2D.body_set_state(ball.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0, at))
	PhysicsServer2D.body_set_state(ball.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, velocity)
