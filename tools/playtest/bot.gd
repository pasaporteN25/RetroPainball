extends RefCounted
## Bot jugador del playtesting (F1a). Juega con las mismas acciones de input que una persona
## (`flipper_left`, `flipper_right`, `launch`) y, el experto, con el nudge del juego.
##
## Los "niveles" son de habilidad del BOT, no de dificultad del juego (el juego no tiene
## dificultades). Lo que cambia entre niveles:
##  - reacción: el bot ve la bola con ese atraso (en segundos de juego) y, según el nivel,
##    corrige parte del atraso extrapolando con la velocidad;
##  - puntería del golpe: error aleatorio del momento en que aprieta el flipper;
##  - retención: si la bola viene lenta, deja el flipper arriba para atraparla y la suelta
##    cuando está en el punto de la paleta que eligió.
## Limitación conocida: el bot no lee las reglas de cada mesa, así que NO apunta a los objetivos
## encendidos (el plan lo pide para medio y experto). Hoy "apuntar" es elegir en qué punto de la
## paleta se golpea la bola. Leer el estado de cada mesa queda para una iteración posterior.

const SKILLS := ["novato", "medio", "experto", "azar"]

## Parámetros por nivel. `reaction`: atraso de visión (s). `lead`: fracción del atraso que corrige
## extrapolando. `aim_error`: desvío (px) del momento del golpe. `catch_p`: probabilidad de retener
## una bola lenta. `hold`: cuánto queda apretado el flipper en un golpe normal (s).
## `nudge`: si usa el empujón. `launch_error`: desvío del tiempo de carga del lanzador (s).
const PROFILES := {
	"novato": {"reaction": 0.18, "lead": 0.0, "aim_error": 34.0, "catch_p": 0.0, "hold": 0.22,
			"nudge": false, "launch_error": 0.35},
	"medio": {"reaction": 0.11, "lead": 0.6, "aim_error": 16.0, "catch_p": 0.4, "hold": 0.15,
			"nudge": false, "launch_error": 0.09},
	"experto": {"reaction": 0.07, "lead": 0.95, "aim_error": 6.0, "catch_p": 0.7, "hold": 0.12,
			"nudge": true, "launch_error": 0.03},
}

const SAMPLE_STEP := 1.0 / 60.0
const LANE_X := 664.0
const LANE_Y := 430.0
## Alto (px) sobre la paleta en que se dispara el flipper, antes del error de puntería.
const TRIGGER_HEIGHT := 40.0
const ZONE_HEIGHT := 90.0
const SLOW_SPEED := 350.0
const MAX_CATCH := 0.55
const NUDGE_COOLDOWN := 3.0

var skill := "medio"

var _rng := RandomNumberGenerator.new()
var _profile: Dictionary
var _table: Node2D
var _balls: Node
var _plunger: Node
## El autoload GameState (se busca en el árbol: con `-s` no existe como identificador al compilar).
var _game: Node
## Cada flipper: {node, action, dir, pivot, length, rest, pressed, release_at, cooldown, jitter, aim}.
var _flippers: Array[Dictionary] = []
var _clock := 0.0
var _sample_clock := 0.0
## Fotos de las bolas en juego: {t, balls: [{pos, vel}]}.
var _history: Array[Dictionary] = []
var _launch_wait := 0.0
var _launch_time := 0.7
var _launching := false
var _random_clock := 0.0
var _random_hold := 0.0
var _nudge_ready_at := 0.0


func _init(new_skill: String, table: Node2D, seed_value: int) -> void:
	skill = new_skill
	_profile = PROFILES.get(skill, {})
	_table = table
	_balls = table.get_node("Balls")
	_plunger = table.get_node("Plunger")
	_game = table.get_tree().root.get_node("GameState")
	_rng.seed = seed_value
	for node_name in ["LeftFlipper", "RightFlipper"]:
		var flipper := table.get_node(node_name)
		var dir := 1.0 if flipper.side == 0 else -1.0
		_flippers.append({
			"node": flipper,
			"action": "flipper_left" if dir > 0.0 else "flipper_right",
			"dir": dir,
			"pivot": table.to_local(flipper.global_position),
			"length": float(flipper.length),
			"rest": float(flipper.rest_angle_deg),
			"pressed": false,
			"release_at": 0.0,
			"cooldown": 0.0,
			"jitter": 0.0,
			"aim": 0.8,
		})
	_new_launch()


## Pivote de cada flipper en coordenadas de la mesa (el runner lo usa para clasificar dónde se pierde la bola).
func pivots() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for f in _flippers:
		result.append(f.pivot)
	return result


func release_all() -> void:
	for f in _flippers:
		_set_pressed(f, false)
	Input.action_release("launch")
	_launching = false


## Avanza `delta` segundos de juego (un paso de física). Llamar una vez por paso.
func tick(delta: float) -> void:
	_clock += delta
	if not _game.playing:
		release_all()
		return
	if skill == "azar":
		_tick_random(delta)
		return
	_sample(delta)
	_tick_launch(delta)
	var observed := _observed()
	for f in _flippers:
		_tick_flipper(f, observed, delta)
	if _profile.nudge:
		_tick_nudge(observed)


# --- Azar: igual que tests/headless/table_random.gd, como control ---------------------------

func _tick_random(delta: float) -> void:
	_random_clock += delta
	if _random_hold > 0.0:
		_random_hold -= delta
		if _random_hold <= 0.0:
			Input.action_release("launch")
		return
	if _random_clock < 0.1:
		return
	_random_clock -= 0.1
	if _game.ball_in_lane and _rng.randf() < 0.4:
		Input.action_press("launch")
		_random_hold = _rng.randf_range(0.35, 0.9)
	for f in _flippers:
		if _rng.randf() < 0.22:
			_set_pressed(f, not f.pressed)


# --- Lanzador -------------------------------------------------------------------------------

## Sortea cuánto espera y cuánto carga el próximo saque. El novato carga cualquier cosa; el resto
## apunta a la ventana del skill shot con un error propio de su nivel.
func _new_launch() -> void:
	var charge_time: float = _plunger.charge_time
	var power := 0.8
	if skill == "novato":
		power = _rng.randf_range(0.25, 1.0)
	elif not _profile.is_empty():
		var mid := (float(_plunger.skill_min) + float(_plunger.skill_max)) * 0.5
		power = clampf(mid + _rng.randfn(0.0, float(_profile.launch_error) / charge_time), 0.2, 1.0)
	_launch_wait = _rng.randf_range(0.3, 0.9)
	_launch_time = power * charge_time


func _tick_launch(delta: float) -> void:
	if _launching:
		_launch_time -= delta
		if _launch_time <= 0.0:
			Input.action_release("launch")
			_launching = false
			_new_launch()
		return
	if not _game.ball_in_lane:
		return
	_launch_wait -= delta
	if _launch_wait <= 0.0:
		Input.action_press("launch")
		_launching = true


# --- Observación con atraso -----------------------------------------------------------------

func _sample(delta: float) -> void:
	_sample_clock += delta
	if _sample_clock < SAMPLE_STEP:
		return
	_sample_clock -= SAMPLE_STEP
	var snapshot: Array = []
	for ball: RigidBody2D in _balls.get_children():
		if ball.is_queued_for_deletion() or ball.freeze:
			continue
		var at := _table.to_local(ball.global_position)
		if at.x > LANE_X and at.y > LANE_Y:
			continue  # en el carril de saque: no se juega con los flippers
		snapshot.append({"pos": at, "vel": ball.linear_velocity})
	_history.append({"t": _clock, "balls": snapshot})
	while _history.size() > 1 and _history[1].t < _clock - float(_profile.reaction):
		_history.pop_front()


## Lo que el bot "ve" ahora: la foto de hace `reaction` segundos, con la posición extrapolada.
func _observed() -> Array:
	if _history.is_empty():
		return []
	var snap: Dictionary = _history[0]
	var age := _clock - float(snap.t)
	var result: Array = []
	for b in snap.balls:
		result.append({"pos": b.pos + b.vel * age * float(_profile.lead), "vel": b.vel})
	return result


# --- Flippers -------------------------------------------------------------------------------

func _set_pressed(f: Dictionary, pressed: bool) -> void:
	if f.pressed == pressed:
		return
	f.pressed = pressed
	if pressed:
		Input.action_press(f.action)
	else:
		Input.action_release(f.action)


## Mejor bola para este flipper: la más baja dentro de su zona de golpe.
## `along` es la distancia sobre la paleta (0 = pivote) y `height`, lo que está sobre su superficie en reposo.
func _target(f: Dictionary, observed: Array) -> Dictionary:
	var best := {}
	for b in observed:
		var rel: Vector2 = b.pos - f.pivot
		var along: float = rel.x * f.dir
		var surface := along * tan(deg_to_rad(f.rest))
		var height := surface - rel.y
		if along < -12.0 or along > f.length + 25.0 or height < -10.0 or height > ZONE_HEIGHT:
			continue
		if b.vel.y < -250.0:
			continue  # sube rápido: todavía no baja a los flippers
		if best.is_empty() or height < best.height:
			best = {"along": along, "height": height, "speed": b.vel.length()}
	return best


func _tick_flipper(f: Dictionary, observed: Array, delta: float) -> void:
	f.cooldown = maxf(0.0, f.cooldown - delta)
	if _game.tilted:
		_set_pressed(f, false)
		return
	if f.pressed:
		if _clock >= f.release_at:
			_set_pressed(f, false)
			f.cooldown = 0.05
			f.jitter = _rng.randfn(0.0, float(_profile.aim_error))
			f.aim = _rng.randf_range(0.55, 0.95)
		return
	if f.cooldown > 0.0:
		return
	var target := _target(f, observed)
	if target.is_empty():
		return
	var slow: bool = target.speed < SLOW_SPEED
	# Una bola lenta que rueda por la paleta se espera hasta el punto elegido; una rápida, se golpea ya.
	if slow and skill != "novato" and target.along < f.length * f.aim and target.along < f.length - 12.0:
		return
	if target.height > TRIGGER_HEIGHT + f.jitter:
		return
	var hold: float = _profile.hold
	if slow and _rng.randf() < float(_profile.catch_p):
		hold = _rng.randf_range(0.3, MAX_CATCH)
	_set_pressed(f, true)
	f.release_at = _clock + hold


# --- Nudge (solo experto) -------------------------------------------------------------------

## Empuja con moderación cuando la bola cae por un costado hacia el outlane, por debajo de los flippers.
func _tick_nudge(observed: Array) -> void:
	if _clock < _nudge_ready_at or _flippers.size() < 2:
		return
	var pivot_y: float = _flippers[0].pivot.y
	var left_x: float = _flippers[0].pivot.x
	var right_x: float = _flippers[1].pivot.x
	for b in observed:
		var outside: bool = b.pos.x < left_x - 20.0 or b.pos.x > right_x + 20.0
		if b.pos.y > pivot_y - 10.0 and outside and b.vel.y > 0.0:
			_nudge_ready_at = _clock + NUDGE_COOLDOWN
			var side := 1.0 if b.pos.x < left_x else -1.0
			_game.nudge(Vector2(side * 0.5, -1.0))
			return
