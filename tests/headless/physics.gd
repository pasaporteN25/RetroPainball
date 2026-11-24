extends SceneTree
## Prueba la mesa de verdad, con física en tiempo real: sacar bola, flippers,
## lanzador, bumpers, que la bola no atraviese paredes, salvavidas, drenaje y
## fin de partida. Tarda unos 15 segundos.
## Uso suelto: Godot_console.exe --headless --path . -s tests/headless/physics.gd

const TMP_RECORD := "user://test_physics_records.cfg"
const Ball := preload("res://scripts/table/ball.gd")

var failures: Array[String] = []
var checks := 0
var main: Node2D
var table: Node2D


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, label: String) -> void:
	checks += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		failures.append(label)


func _run() -> void:
	var game_state: Node = root.get_node("GameState")
	var old_path: String = game_state.record_path
	game_state.record_path = TMP_RECORD
	game_state.save_directory = ""
	game_state.high_score = 0

	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	table = main.get_node("Table")
	await _test_serve(game_state)
	await _test_flippers()
	await _test_launch()
	await _test_ball_save(game_state)  # justo después de lanzar, mientras corre el salvavidas
	await _test_no_tunneling()
	await _test_bumper(game_state)
	await _test_game_over(game_state)

	main.queue_free()
	await process_frame
	_cleanup()
	game_state.record_path = old_path
	print("\nFísica: %d controles / %d fallos" % [checks, failures.size()])
	for f in failures:
		print("  FALLÓ: %s" % f)
	quit(0 if failures.is_empty() else 1)


func _test_serve(game_state: Node) -> void:
	check(game_state.playing, "la partida arranca sola")
	check(game_state.balls_left == 3, "arranca con 3 bolas")
	await _wait(1.0)
	check(_balls().size() == 1, "sale una bola")
	check(game_state.ball_in_lane, "la bola queda en el carril del lanzador")


func _test_flippers() -> void:
	var left: Node2D = table.get_node("LeftFlipper")
	var right: Node2D = table.get_node("RightFlipper")
	var left_rest := left.rotation
	var right_rest := right.rotation
	check(left_rest > 0.4 and right_rest < -0.4, "en reposo las puntas apuntan hacia abajo")
	Input.action_press("flipper_left")
	await _wait(0.1)
	check(left.rotation < -0.4, "el flipper izquierdo sube en menos de 0,1 s")
	check(is_equal_approx(right.rotation, right_rest), "el derecho no se mueve con la tecla izquierda")
	Input.action_release("flipper_left")
	Input.action_press("flipper_right")
	await _wait(0.15)
	check(right.rotation > 0.4, "el flipper derecho sube")
	check(is_equal_approx(left.rotation, left_rest), "el izquierdo vuelve a reposo")
	Input.action_release("flipper_right")
	await _wait(0.15)


func _test_launch() -> void:
	var ball: RigidBody2D = _balls()[0]
	var start_y := ball.global_position.y
	Input.action_press("launch")
	await _wait(1.0)
	var plunger: Node2D = table.get_node("Plunger")
	check(plunger.charge > 0.95, "mantener carga el lanzador al máximo")
	Input.action_release("launch")
	var top := start_y
	for i in 40:
		await physics_frame
		top = minf(top, ball.global_position.y)
	await _wait(0.5)
	top = minf(top, ball.global_position.y)
	check(start_y - top > 900.0, "con carga completa la bola sube más de 900 px (subió %.0f)" % (start_y - top))
	check(_inside_table(ball), "después del lanzamiento la bola sigue dentro de la mesa")


func _test_no_tunneling() -> void:
	# Bolas a velocidad máxima contra las paredes: ninguna tiene que escaparse.
	var shots: Array[RigidBody2D] = []
	var dirs := [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2(-1, -1).normalized(), Vector2(1, -1).normalized()]
	for i in dirs.size():
		shots.append(_spawn(Vector2(336, 770 + 45 * i), dirs[i] * 4200.0))
	# Se controla en cada paso: una bola que drena se libera y deja de contar.
	var escaped_ids := {}
	for step in 144:  # 0,6 s a 240 Hz
		await physics_frame
		for b in shots:
			if is_instance_valid(b) and not b.is_queued_for_deletion() and not _inside_table(b):
				escaped_ids[b.get_instance_id()] = true
	var escaped := escaped_ids.size()
	for b in shots:
		if is_instance_valid(b):
			b.queue_free()
	check(escaped == 0, "ninguna bola atraviesa las paredes a 4200 px/s (%d se escaparon)" % escaped)
	await _wait(0.1)


func _test_bumper(game_state: Node) -> void:
	var bumper: Node2D = table.get_node("BumperLeft")
	var before: int = game_state.score
	var ball := _spawn(bumper.position + Vector2(0, -80), Vector2(0, 900))
	var max_speed := 0.0
	for i in 60:
		await physics_frame
		max_speed = maxf(max_speed, ball.linear_velocity.length())
	check(game_state.score - before >= 100, "el bumper suma puntos (sumó %d)" % (game_state.score - before))
	check(max_speed >= 1200.0, "el bumper despide la bola (%.0f px/s)" % max_speed)
	ball.queue_free()
	await _wait(0.1)


func _test_ball_save(game_state: Node) -> void:
	check(main._ball_save_left > 0.0, "después de lanzar corre el tiempo de salvavidas")
	var ball: RigidBody2D = _balls()[0]
	_teleport(ball, Vector2(336, 1500))
	await _wait(0.2)
	check(game_state.balls_left == 3, "con salvavidas, drenar no resta bola")
	await _wait(0.8)
	check(_balls().size() == 1 and game_state.ball_in_lane, "con salvavidas vuelve a salir bola al carril")
	check(not main._save_armed, "la bola que vuelve de una salvada no rearma el salvavidas (una salvada por bola)")


func _test_game_over(game_state: Node) -> void:
	var ended := [false]
	game_state.game_ended.connect(func(_s: int, _r: bool) -> void: ended[0] = true)
	main._ball_save_left = 0.0
	main._save_armed = false
	_teleport(_balls()[0], Vector2(336, 1500))
	await _wait(0.2)
	check(game_state.balls_left == 2, "sin salvavidas, drenar resta una bola")
	await _wait(0.8)
	_teleport(_balls()[0], Vector2(336, 1500))
	await _wait(1.0)
	_teleport(_balls()[0], Vector2(336, 1500))
	await _wait(0.3)
	check(game_state.balls_left == 0 and not game_state.playing, "con la última bola termina la partida")
	check(ended[0], "se avisa el fin de partida")
	check(FileAccess.file_exists(TMP_RECORD), "el récord se guarda (en el archivo de test)")


# --- ayudas ---

func _balls() -> Array[RigidBody2D]:
	var out: Array[RigidBody2D] = []
	for b in table.get_node("Balls").get_children():
		if not b.is_queued_for_deletion():
			out.append(b)
	return out


func _spawn(pos: Vector2, velocity: Vector2) -> RigidBody2D:
	var ball := Ball.new()
	ball.position = pos
	ball.linear_velocity = velocity
	table.get_node("Balls").add_child(ball)
	return ball


func _teleport(ball: RigidBody2D, pos: Vector2) -> void:
	PhysicsServer2D.body_set_state(ball.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0.0, table.to_global(pos)))
	PhysicsServer2D.body_set_state(ball.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)


func _inside_table(ball: RigidBody2D) -> bool:
	var p := table.to_local(ball.global_position)
	return p.x > 16.0 and p.x < 708.0 and p.y > 126.0 and p.y < 1800.0


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _cleanup() -> void:
	if FileAccess.file_exists(TMP_RECORD):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP_RECORD))
