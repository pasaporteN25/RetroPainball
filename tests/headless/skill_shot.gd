extends SceneTree
## G-09: skill shot según la potencia del lanzador, en las tres mesas.

const Ball := preload("res://scripts/table/ball.gd")
const TABLES := ["res://scenes/main.tscn", "res://scenes/nautilus.tscn", "res://scenes/dracula.tscn"]

var _state: Node
var _table: Node2D
var _checks := 0
var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_state = root.get_node("GameState")
	_state.save_directory = ""
	_state.record_path = "user://test_skill_shot_%d.cfg" % OS.get_process_id()
	for path in TABLES:
		change_scene_to_file(path)
		await scene_changed
		_table = current_scene.get_node("Table")
		await _settle()
		await _test_window()
		await _test_award()
		await _test_launch(0.80, true)
		await _test_launch(0.45, false)
		await _test_launch(1.0, false)
	print("Skill shot: %d controles / %d fallos" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


## Espera el primer saque y deja la mesa sin bolas para controlar la prueba.
func _settle() -> void:
	await create_timer(1.0).timeout
	for ball in _table.get_node("Balls").get_children():
		ball.free()
	_state.score = 0


func _test_window() -> void:
	var label: String = _state.table_id
	var plunger: Node = _table.get_node("Plunger")
	var skill: Node = _table.get_node("SkillShot")
	_check(plunger.in_skill_window(0.8) and not plunger.in_skill_window(0.4) and not plunger.in_skill_window(1.0),
		"%s: la ventana es 0.70..0.90 de potencia" % label)
	skill.on_launched(0.4)
	_check(not skill.armed, "%s: poca potencia no arma el skill shot" % label)
	skill.on_launched(0.8)
	_check(skill.armed, "%s: la potencia dentro de la ventana lo arma" % label)
	skill.disarm()


func _test_award() -> void:
	var label: String = _state.table_id
	var skill: Node = _table.get_node("SkillShot")
	var center: Vector2 = skill.lane_rect.get_center()
	skill.on_launched(0.8)
	var before: int = _state.score
	var ball := _spawn(center, Vector2.ZERO)
	await create_timer(0.1).timeout
	_check(_state.score == before + skill.award and not skill.armed, "%s: entrar al carril armado da el premio una vez" % label)
	ball.free()
	skill.disarm()
	before = _state.score
	ball = _spawn(center, Vector2.ZERO)
	await create_timer(0.1).timeout
	_check(_state.score == before, "%s: sin armar el carril no da premio" % label)
	ball.free()
	# El premio vence si la bola tarda: queda desarmado tras SKILL_TIME.
	skill.on_launched(0.8)
	await create_timer(skill.SKILL_TIME + 0.3).timeout
	_check(not skill.armed, "%s: el skill shot vence a los %d s" % [label, int(skill.SKILL_TIME)])


## Lanza de verdad con una potencia y mira si la bola llega al carril dentro de la ventana de tiempo.
func _test_launch(power: float, expect_award: bool) -> void:
	var label: String = _state.table_id
	await _settle()
	var plunger: Node = _table.get_node("Plunger")
	var skill: Node = _table.get_node("SkillShot")
	var awarded := [false]
	var on_scored := func(_award: int) -> void: awarded[0] = true
	skill.scored.connect(on_scored)
	var ball := _spawn(plunger.position + Vector2(0.0, -Ball.RADIUS - 1.0), Vector2.ZERO)
	await create_timer(0.3).timeout
	plunger.charge = power
	plunger._fire()
	for i in 420:
		await physics_frame
		if awarded[0]:
			break
	_check(awarded[0] == expect_award, "%s: lanzar con potencia %.2f %s skill shot" % [
		label, power, "da" if expect_award else "no da"])
	skill.scored.disconnect(on_scored)
	if is_instance_valid(ball):
		ball.free()
	skill.disarm()


func _spawn(at: Vector2, velocity: Vector2) -> RigidBody2D:
	var ball := Ball.new()
	ball.position = at
	ball.linear_velocity = velocity
	_table.get_node("Balls").add_child(ball)
	return ball


func _check(ok: bool, description: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", description])
