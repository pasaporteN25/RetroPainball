extends RefCounted
## Una sesión de playtesting (F1a): un bot juega partidas completas en una mesa hasta cumplir
## cierta cantidad de bolas, y se devuelven las métricas. Lo usan `run.gd` (la herramienta) y el
## test chico `tests/headless/playtest_bot.gd`.
##
## Corre atado a los pasos de física (no a timers), así el bot y el juego avanzan en lockstep y,
## con la misma semilla, `Engine.time_scale` no debería cambiar el resultado.

const Bot := preload("res://tools/playtest/bot.gd")

const TABLES := {
	"kernel_panic": "res://scenes/main.tscn",
	"nautilus": "res://scenes/nautilus.tscn",
	"dracula": "res://scenes/dracula.tscn",
	"alicia": "res://scenes/alicia.tscn",
}
const FIELD := Vector2(720.0, 1800.0)
const HEAT_CELL := 30.0
const HEAT_SAMPLE := 0.05
## Tope de seguridad: si una bola dura más que esto (segundos de juego), se corta la sesión.
const MAX_BALL_SECONDS := 900.0

var _tree: SceneTree
var _table: Node2D
var _bot: Bot
var _records: Array[Dictionary] = []
var _heat := PackedInt32Array()
var _heat_clock := 0.0
var _messages := {}
var _points := {}
var _ball_clock := 0.0
var _ball_start_score := 0
var _last_pos := Vector2.ZERO
var _max_balls := 0
var _balls_done := 0
var _games := 0
var _tilts := 0
var _saves := 0
var _stuck := 0
var _game_clock := 0.0
var _pivots: Array[Vector2] = []
var _escaped_start := 0
var _cut := false
## Con true imprime cada bola perdida (depuración).
var verbose := false
## Acelera solo con time_scale (pasos de física más grandes). Solo para la comparación de F1a.
var naive := false


func _init(tree: SceneTree) -> void:
	_tree = tree


## Juega `balls` bolas (cada bola perdida cuenta una, incluidas las repetidas por bola extra).
## Devuelve {"records": Array[Dictionary], "summary": Dictionary}. `speed` es Engine.time_scale.
func play(table_id: String, skill: String, balls: int, seed_value: int, speed: float) -> Dictionary:
	var started_ms := Time.get_ticks_msec()
	var game: Node = _tree.root.get_node("GameState")
	var scratch := "user://playtest_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	game.record_path = scratch.path_join("records.cfg")
	game.save_directory = ""
	seed(seed_value)  # el azar global del juego (efectos, saque) también queda fijo
	_tree.change_scene_to_file(TABLES[table_id])
	await _tree.scene_changed
	await _tree.physics_frame
	await _tree.physics_frame
	_table = _tree.current_scene.get_node("Table")
	_bot = Bot.new(skill, _table, seed_value)
	_pivots = _bot.pivots()
	_heat.resize(int(FIELD.x / HEAT_CELL) * int(FIELD.y / HEAT_CELL))
	_escaped_start = _tree.current_scene.escaped_balls
	game.ball_lost.connect(_on_ball_lost)
	game.message.connect(_on_message)
	game.scored.connect(_on_scored)
	game.tilt_changed.connect(_on_tilt)
	game.game_ended.connect(_on_game_ended)
	_table.get_node("Balls").child_entered_tree.connect(_on_ball_added)
	# Godot escala el delta de cada paso de física por Engine.time_scale, pero NO la cantidad de pasos
	# por segundo: con time_scale 4 a secas, cada paso simula 4 veces más tiempo (pasos grandes: más
	# tunneling y otra física). Para acelerar sin cambiar la física se multiplican los pasos por
	# segundo por el mismo factor, así cada paso sigue simulando 1/240 s. `naive` apaga eso (solo para
	# comparar, ver tools/playtest/README.md).
	var base_ticks := Engine.physics_ticks_per_second
	var base_max_steps := Engine.max_physics_steps_per_frame
	var step := 1.0 / float(base_ticks)
	Engine.time_scale = speed
	if not naive:
		Engine.physics_ticks_per_second = int(round(base_ticks * speed))
		Engine.max_physics_steps_per_frame = int(ceil(base_max_steps * speed))
	else:
		step *= speed
	while _balls_done < balls and not _cut:
		await _tree.physics_frame
		if not game.playing:
			game.start_game()
			_games += 1
			_ball_start_score = 0
		_bot.tick(step)
		_observe(step)
		if verbose and int(_game_clock / step) % 1200 == 0:
			print("  t=%.0f wall=%.1f playing=%s lane=%s balls=%d at=%s" % [_game_clock, Time.get_ticks_msec() / 1000.0, game.playing, game.ball_in_lane, _table.get_node("Balls").get_child_count(), _last_pos.round()])
		if _ball_clock > MAX_BALL_SECONDS:
			push_warning("Playtest: una bola superó %d s; se corta la sesión" % int(MAX_BALL_SECONDS))
			_cut = true
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = base_ticks
	Engine.max_physics_steps_per_frame = base_max_steps
	_bot.release_all()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch))
	var summary := {
		"type": "summary", "table": table_id, "bot": skill, "seed": seed_value, "speed": speed,
		"balls": _balls_done, "games": _games, "game_seconds": snappedf(_game_clock, 0.01),
		"wall_seconds": snappedf((Time.get_ticks_msec() - started_ms) / 1000.0, 0.1),
		"tilts": _tilts, "saves": _saves, "stuck": _stuck, "cut": _cut,
		"escaped": _tree.current_scene.escaped_balls - _escaped_start, "max_balls": _max_balls,
		"messages": _messages, "points": _points,
		"heat": {"cell": HEAT_CELL, "w": int(FIELD.x / HEAT_CELL), "h": int(FIELD.y / HEAT_CELL),
				"counts": Array(_heat)},
	}
	return {"records": _records, "summary": summary}


func _observe(step: float) -> void:
	_game_clock += step
	_ball_clock += step
	_heat_clock += step
	var in_play := 0
	var lowest := Vector2(-1.0, -1.0)
	for ball: RigidBody2D in _table.get_node("Balls").get_children():
		if ball.is_queued_for_deletion():
			continue
		in_play += 1
		var at := _table.to_local(ball.global_position)
		if at.y > lowest.y:
			lowest = at
		if _heat_clock >= HEAT_SAMPLE and not ball.freeze:
			var cx := clampi(int(at.x / HEAT_CELL), 0, int(FIELD.x / HEAT_CELL) - 1)
			var cy := clampi(int(at.y / HEAT_CELL), 0, int(FIELD.y / HEAT_CELL) - 1)
			_heat[cy * int(FIELD.x / HEAT_CELL) + cx] += 1
	if _heat_clock >= HEAT_SAMPLE:
		_heat_clock = 0.0
	if in_play > 0:
		_last_pos = lowest
	_max_balls = maxi(_max_balls, in_play)


## Por dónde se perdió la bola, según dónde estaba al irse (respecto de los pivotes de los flippers).
func _zone(at: Vector2) -> String:
	if _pivots.size() < 2:
		return "centro"
	if at.x < _pivots[0].x:
		return "outlane_izq"
	if at.x > _pivots[1].x:
		return "outlane_der"
	return "centro"


func _on_ball_lost() -> void:
	var game: Node = _tree.root.get_node("GameState")
	_records.append({
		"type": "ball", "n": _balls_done + 1, "points": game.ball_points,
		"seconds": snappedf(_ball_clock, 0.01), "zone": _zone(_last_pos),
		"kickback": game.kickback_ready, "game": _games,
	})
	_balls_done += 1
	if verbose:
		print("  bola %d: %d pts, %.1f s, %s" % [_balls_done, game.ball_points, _ball_clock, _zone(_last_pos)])
	_ball_clock = 0.0


func _on_game_ended(final_score: int, _is_record: bool) -> void:
	_records.append({"type": "game", "n": _games, "score": final_score})


func _on_message(text: String) -> void:
	if text.contains("SALVADA"):
		_saves += 1
	var key := text.to_upper()
	for digit in "0123456789":
		key = key.replace(digit, "#")
	_messages[key] = int(_messages.get(key, 0)) + 1


func _on_scored(points: int, _at: Vector2) -> void:
	var key := str(points)
	_points[key] = int(_points.get(key, 0)) + 1


func _on_tilt(tilted: bool) -> void:
	if tilted:
		_tilts += 1


func _on_ball_added(node: Node) -> void:
	if node.has_signal("stuck"):
		node.stuck.connect(func() -> void: _stuck += 1)
