extends SceneTree
## Prueba golpes reales, duración de los efectos y limpieza al salir de cada mesa.

const Ball := preload("res://scripts/table/ball.gd")
const Burst := preload("res://scripts/fx/table_burst.gd")
const ScorePopup := preload("res://scripts/fx/score_popup.gd")
const SCENES := ["res://scenes/main.tscn", "res://scenes/nautilus.tscn"]

var _failures := 0
var _checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	state.record_path = "user://test_fx_%d.cfg" % OS.get_process_id()
	state.save_directory = ""
	var orphan_count := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	for path in SCENES:
		await _test_table(path)
		_check(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) == orphan_count,
			"%s no deja nodos huérfanos" % path.get_file())
	print("Visuales: %d controles / %d fallos" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _test_table(path: String) -> void:
	var game := (load(path) as PackedScene).instantiate()
	root.add_child(game)
	var table := game.get_node("Table") as Node2D
	var shake := game.get_node("ScreenShake")
	var resting := root.canvas_transform
	var bumper := table.get_node("BumperLeft") as Node2D
	var sling := table.get_node("LeftSlingshot/Shape") as CollisionPolygon2D
	var a := sling.to_global(sling.polygon[0])
	var b := sling.to_global(sling.polygon[1])
	var rubber := a.lerp(b, 0.5)
	var normal := (b - a).orthogonal().normalized()
	normal *= signf(normal.x)

	shake.on_impact(1000.0, Vector2.RIGHT)
	_check(not shake.is_processing(), "un golpe suave no mueve la pantalla")
	await _hit(table, bumper.global_position, Vector2.DOWN, bumper.radius + 58.0, "bumper")
	await create_timer(0.3).timeout
	await _hit(table, rubber, normal, 60.0, "slingshot")

	# Pausar justo en pleno movimiento también tiene que devolver el lienzo a su lugar.
	paused = true
	_check(root.canvas_transform.is_equal_approx(resting), "pausar restablece el lienzo")
	paused = false
	await create_timer(0.75).timeout
	_check(table.get_node("FX").get_child_count() == 0, "las chispas y los popups se liberan solos")

	var mission := table.get_node_or_null("DepthMission")
	if mission:
		mission.restore(0b101, mission.DEPTH_STEP)
		_check(table.get_node("Sonars/Port")._lit and not table.get_node("Sonars/Bow")._lit
			and table.get_node("Sonars/Starboard")._lit
			and table.get_node("PlayfieldArt")._depth == mission.DEPTH_STEP,
			"restaurar la misión actualiza sonares y profundidad")
		mission.reset()
		_check(not table.get_node("Sonars/Port")._lit and table.get_node("PlayfieldArt")._depth == 0,
			"reiniciar apaga los insertos de la misión")
	else:
		await _check_kernel_insert(table, "Boot", Vector2(336, 418), Vector2(0, 490))
		await _check_kernel_insert(table, "StandupLeft", Vector2(222, 884), Vector2(0, -950))

	# Salir con efectos vivos verifica también su limpieza por propiedad del árbol.
	root.get_node("GameState").add_score(100, bumper.global_position)
	shake.on_impact(2800.0, Vector2.RIGHT)
	await create_timer(0.035).timeout
	game.queue_free()
	await process_frame
	await process_frame
	_check(root.canvas_transform.is_equal_approx(resting), "salir restablece el lienzo")


func _hit(table: Node2D, at: Vector2, normal: Vector2, distance: float, label: String) -> void:
	var ball := _spawn(table, table.to_local(at + normal * distance), -normal * 1700.0)
	var fx := table.get_node("FX")
	var spark_count := -1
	var has_popup := false
	var offset := Vector2.ZERO
	var start := root.canvas_transform.origin
	var deadline := create_timer(0.18)
	while deadline.time_left > 0.0:
		await process_frame
		for effect in fx.get_children():
			if effect.global_position.distance_to(at) > 90.0:
				continue
			if effect is Burst:
				spark_count = effect._velocities.size()
			elif effect is ScorePopup:
				has_popup = true
		offset = root.canvas_transform.origin - start
		if spark_count > 0 and has_popup and not offset.is_zero_approx():
			break
	_check(spark_count > 0 and spark_count <= Burst.MAX_SPARKS and has_popup,
		"%s genera chispas y popup con un golpe real" % label)
	_check(offset.length() > 0.0 and offset.length() <= 4.01, "%s genera una sacudida acotada" % label)
	_check(not ball._trail_positions.is_empty() and ball._trail_positions.size() <= Ball.TRAIL_SAMPLE_LIMIT,
		"%s deja una estela acotada" % label)
	ball.queue_free()


func _check_kernel_insert(table: Node2D, piece_name: String, at: Vector2, velocity: Vector2) -> void:
	var piece := table.get_node("KernelLayout/" + piece_name)
	_check(piece._flash == 0.0, "%s empieza apagado" % piece_name)
	var ball := _spawn(table, at, velocity)
	await create_timer(0.16).timeout
	_check(piece._flash > 0.0, "%s se enciende al activarlo con la bola" % piece_name)
	ball.queue_free()
	await create_timer(0.5).timeout
	_check(piece._flash == 0.0, "%s vuelve a apagarse" % piece_name)


func _spawn(table: Node2D, at: Vector2, velocity: Vector2) -> RigidBody2D:
	var ball := Ball.new()
	ball.position = at
	ball.linear_velocity = velocity
	table.get_node("Balls").add_child(ball)
	return ball


func _check(ok: bool, description: String) -> void:
	_checks += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", description])
	if not ok:
		_failures += 1
