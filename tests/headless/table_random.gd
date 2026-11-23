extends SceneTree
## Q-04: juega al azar en cada mesa (semilla fija) y comprueba que ninguna bola se escapa del
## campo, se queda quieta, vuelve al carril de saque o pasa mucho tiempo sin bajar a los flippers.

const MESAS := ["res://scenes/main.tscn", "res://scenes/nautilus.tscn", "res://scenes/dracula.tscn", "res://scenes/alicia.tscn"]
const SIM_SECONDS := 60.0
const STEP := 0.1
const LANE_X := 670.0
const LANE_Y := 460.0
const FLIPPER_ZONE_Y := 1000.0
const MAX_STILL := 9.0
const MAX_ABOVE_FLIPPERS := 30.0
const TIME_SCALE := 3.0

var _game: Node
var _checks := 0
var _errors := 0
var _scratch := "user://test_table_random_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_game = root.get_node("GameState")
	_game.record_path = _scratch.path_join("records.cfg")
	_game.save_directory = ""
	for path: String in MESAS:
		await _play(path)
	Input.action_release("launch")
	Input.action_release("flipper_left")
	Input.action_release("flipper_right")
	Engine.time_scale = 1.0
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_scratch))
	print("Mesas al azar: %d controles / %d fallos" % [_checks, _errors])
	quit(0 if _errors == 0 else 1)


func _play(path: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261120
	if not _check(change_scene_to_file(path) == OK, "%s abre" % path.get_file()):
		return
	await scene_changed
	await create_timer(0.8).timeout
	var table := current_scene.get_node("Table")
	var balls := table.get_node("Balls")
	Engine.time_scale = TIME_SCALE
	var info := {}  # id -> {left_lane, last_at, still, above}
	var problems := {}
	var launch_left := 0.0
	var served := 0
	var elapsed := 0.0
	while elapsed < SIM_SECONDS:
		await create_timer(STEP).timeout
		elapsed += STEP
		if not _game.playing:
			_game.start_game()
		if launch_left > 0.0:
			launch_left -= STEP
			if launch_left <= 0.0:
				Input.action_release("launch")
		elif _game.ball_in_lane and rng.randf() < 0.4:
			Input.action_press("launch")
			launch_left = rng.randf_range(0.35, 0.9)
			served += 1
		for action in ["flipper_left", "flipper_right"]:
			if rng.randf() < 0.22:
				if Input.is_action_pressed(action):
					Input.action_release(action)
				else:
					Input.action_press(action)
		for ball: RigidBody2D in balls.get_children():
			if ball.is_queued_for_deletion():
				continue
			var at: Vector2 = table.to_local(ball.global_position)
			var id := ball.get_instance_id()
			if not info.has(id):
				info[id] = {"left_lane": false, "last_at": at, "still": 0.0, "above": 0.0}
			var state: Dictionary = info[id]
			var in_lane := at.x > LANE_X and at.y > LANE_Y
			if not in_lane and not ball.freeze:
				state.left_lane = true
			if in_lane and state.left_lane and not problems.has("lane"):
				problems["lane"] = "la bola volvió al carril de saque en %s (t=%.0f s)" % [at.round(), elapsed]
			# main.gd rescata las bolas que escapan (margen 48 px); si una sigue lejos, el rescate falló.
			if at.x < -200.0 or at.x > 920.0 or at.y < -200.0 or at.y > 2000.0:
				if not problems.has("fuera"):
					problems["fuera"] = "la bola salió del campo en %s (t=%.0f s)" % [at.round(), elapsed]
			if at.distance_to(state.last_at) > 6.0 or ball.freeze:
				state.last_at = at
				state.still = 0.0
			elif not in_lane:
				state.still += STEP
				if state.still > MAX_STILL and not problems.has("quieta"):
					problems["quieta"] = "la bola quedó quieta %.0f s en %s" % [state.still, at.round()]
			if at.y > FLIPPER_ZONE_Y or not state.left_lane:
				state.above = 0.0
			else:
				state.above += STEP
				if state.above > MAX_ABOVE_FLIPPERS and not problems.has("ciclo"):
					problems["ciclo"] = "la bola estuvo %.0f s sin bajar a los flippers (¿ciclo?) en %s" % [state.above, at.round()]
	Engine.time_scale = 1.0
	Input.action_release("launch")
	Input.action_release("flipper_left")
	Input.action_release("flipper_right")
	if current_scene.escaped_balls > 0:
		# El test avanza el tiempo x3 (pasos de física más grandes), lo que favorece el tunneling.
		print("AVISO %s: %d bola(s) atravesaron una pared y fueron rescatadas" % [path.get_file(), current_scene.escaped_balls])
	_check(served >= 2, "%s: el azar lanzó al menos 2 bolas (%d)" % [path.get_file(), served])
	for key in ["lane", "fuera", "quieta", "ciclo"]:
		_check(not problems.has(key), "%s: %s" % [path.get_file(), problems.get(key, "sin problemas de '%s'" % key)])


func _check(ok: bool, label: String) -> bool:
	_checks += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		_errors += 1
	return ok
