extends SceneTree
## G-01: el Resource TablePhysics trae los valores de siempre, la mesa lo carga, las
## piezas lo leen y, sin Resource, las piezas siguen con sus valores de antes.
## Uso suelto: godot --headless --path . -s tests/headless/table_physics.gd

const Ball := preload("res://scripts/table/ball.gd")

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, label: String) -> void:
	checks += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		failures.append(label)


func _run() -> void:
	root.get_node("GameState").save_directory = ""
	_test_defaults()
	await _test_pieces_read_resource()
	await _test_fallback()
	TablePhysics.use(null)
	print("\nTablePhysics: %d controles / %d fallos" % [checks, failures.size()])
	for f in failures:
		print("  FALLÓ: %s" % f)
	quit(0 if failures.is_empty() else 1)


func _test_defaults() -> void:
	var res := load(TablePhysics.DEFAULT_PATH) as TablePhysics
	check(res != null, "el .tres por defecto carga")
	if res == null:
		return
	check(res.gravity == ProjectSettings.get_setting("physics/2d/default_gravity"), "gravedad = project.godot")
	check(res.ball_radius == Ball.RADIUS, "radio de bola = Ball.RADIUS")
	check(res.ball_bounce == 0.2 and res.ball_friction == 0.25 and res.ball_max_speed == 4200.0, "bola: valores de siempre")
	check(res.flipper_up_speed == 26.0 and res.flipper_down_speed == 16.0, "flippers: velocidades de siempre")
	check(res.flipper_bounce == 0.0 and res.flipper_friction == 0.8, "flippers: rebote y fricción de siempre")
	check(res.bumper_bounce == 0.0 and res.bumper_kick_speed == 1300.0 and res.bumper_tangent_keep == 0.5, "bumpers: valores de siempre")
	check(res.slingshot_bounce == 0.25 and res.slingshot_kick_speed == 1000.0, "slingshots: valores de siempre")
	check(res.plunger_min_speed == 1200.0 and res.plunger_max_speed == 3000.0, "lanzador: valores de siempre")


func _test_pieces_read_resource() -> void:
	var phys := TablePhysics.new()
	phys.gravity = 900.0
	phys.ball_bounce = 0.7
	phys.ball_max_speed = 1234.0
	phys.flipper_up_speed = 11.0
	phys.bumper_kick_speed = 777.0
	phys.slingshot_kick_speed = 555.0
	phys.plunger_max_speed = 2500.0
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	main.physics = phys
	root.add_child(main)
	await create_timer(1.2).timeout
	var space := main.get_viewport().world_2d.space
	check(is_equal_approx(PhysicsServer2D.area_get_param(space, PhysicsServer2D.AREA_PARAM_GRAVITY), 900.0), "la mesa aplica la gravedad")
	var table := main.get_node("Table")
	var ball: Ball = table.get_node("Balls").get_child(0)
	check(ball != null and is_equal_approx(ball.physics_material_override.bounce, 0.7) and ball.max_speed == 1234.0, "la bola lee rebote y velocidad máxima")
	var flipper := table.get_node("LeftFlipper")
	check(flipper.up_speed == 11.0, "el flipper lee su velocidad")
	check(table.get_node("Plunger").max_speed == 2500.0, "el lanzador lee su fuerza máxima")
	check(table.get_node("LeftSlingshot").kick_speed == 555.0, "el slingshot lee su patada")
	for node in table.get_children():
		if node.get_script() != null and str(node.get_script().resource_path).ends_with("bumper.gd"):
			check(node.kick_speed == 777.0, "el bumper lee su patada")
			break
	main.queue_free()
	await process_frame


func _test_fallback() -> void:
	TablePhysics.use(null)
	var ball := Ball.new()
	root.add_child(ball)
	check(is_equal_approx(ball.physics_material_override.bounce, 0.2) and ball.max_speed == 4200.0, "sin asignar, la bola usa los valores por defecto")
	ball.queue_free()
	var bare := TablePhysics.new()
	check(bare.ball_radius == 16.0 and bare.plunger_max_speed == 3000.0, "una instancia nueva ya trae los valores de siempre")
	await process_frame
