extends RefCounted
## Bot jugador del playtesting (F1a, puntería en F1). Juega con las mismas acciones de input que una
## persona (`flipper_left`, `flipper_right`, `launch`) y, el experto, con el nudge del juego.
##
## Los "niveles" son de habilidad del BOT, no de dificultad del juego (el juego no tiene
## dificultades). Lo que cambia entre niveles:
##  - reacción: el bot ve la bola con ese atraso (en segundos de juego) y corrige parte del atraso
##    extrapolando con la velocidad y la gravedad (`lead`);
##  - timing: error aleatorio (s) del momento en que aprieta el flipper;
##  - puntería: con probabilidad `aim_p` elige DÓNDE de la paleta pegarle a una bola lenta para
##    mandarla a lo que esté encendido (lee las reglas con `aim.gd`), con un error de `aim_error` px;
##  - atrape: con probabilidad `catch_p` levanta el flipper antes de que llegue la bola, la deja
##    asentarse en la paleta alzada y recién ahí la suelta para tirar con puntería.
##
## Cómo decide cada flipper: por cada bola predice (balística con gravedad) cuándo y en qué punto de
## la paleta en reposo va a hacer contacto. Si es rápida, aprieta justo antes del contacto (o antes, si
## decidió atraparla); si es lenta y rueda por la paleta, espera a que llegue al punto elegido.

const Aim := preload("res://tools/playtest/aim.gd")

const SKILLS := ["novato", "medio", "experto", "azar"]

## Parámetros por nivel. `reaction`: atraso de visión (s). `lead`: fracción del atraso que corrige
## extrapolando. `timing`: desvío (s) del momento del golpe. `aim_p`: probabilidad de apuntar a un
## blanco encendido (si no, golpea en un punto cualquiera). `aim_error`: desvío (px) del punto de la
## paleta elegido. `catch_p`: probabilidad de atrapar una bola rápida. `hold`: cuánto queda apretado el
## flipper en un golpe normal (s). `nudge`: si usa el empujón. `launch_error`: desvío del tiempo de
## carga del lanzador (s).
const PROFILES := {
	"novato": {"reaction": 0.18, "lead": 0.0, "timing": 0.045, "aim_p": 0.0, "aim_error": 30.0,
			"catch_p": 0.0, "catch_max": 0.0, "hold": 0.22, "nudge": false, "launch_error": 0.35},
	"medio": {"reaction": 0.08, "lead": 0.9, "timing": 0.012, "aim_p": 0.7, "aim_error": 12.0,
			"catch_p": 0.5, "catch_max": 450.0, "hold": 0.15, "nudge": false, "launch_error": 0.09},
	"experto": {"reaction": 0.05, "lead": 1.0, "timing": 0.006, "aim_p": 0.95, "aim_error": 6.0,
			"catch_p": 0.6, "catch_max": 450.0, "hold": 0.12, "nudge": true, "nudge_up": 350.0,
			"nudge_cd": 1.4, "launch_error": 0.03},
}

const SAMPLE_STEP := 1.0 / 60.0
const LANE_X := 664.0
const LANE_Y := 430.0
const GRAVITY := 1600.0
## Altura (px, en vertical) del centro de la bola sobre la línea de la paleta cuando la toca.
const CONTACT_HEIGHT := 27.0
## Cuánto antes del contacto (s) se aprieta para pegarle a una bola rápida, antes del error de timing.
const PRESS_LEAD := 0.035
## Cuánto antes del contacto (s) se levanta el flipper para atrapar una bola.
const CATCH_LEAD := 0.14
const PREDICT_STEP := 1.0 / 120.0
const PREDICT_HORIZON := 0.7
## Por debajo de esta velocidad (px/s) la bola "rueda" por la paleta y se espera al punto elegido.
const SLOW_SPEED := 350.0
## Una bola con menos velocidad que esta, sobre la paleta alzada, ya se asentó.
const SETTLED_SPEED := 230.0
const SETTLED_TIME := 0.12
const MAX_CATCH := 1.6
const NUDGE_COOLDOWN := 3.0
const AIM_REFRESH := 0.3
## Calibración medida (bola quieta sobre la paleta izquierda en reposo): distancia al pivote -> ángulo
## (grados desde la vertical, hacia el centro de la mesa) con que sale la bola al apretar.
const AIM_ALONG := [10.0, 25.0, 40.0, 55.0, 70.0, 85.0, 100.0]
const AIM_ANGLE := [0.3, 4.4, 6.9, 11.1, 21.8, 30.5, 47.9]

var skill := "medio"

var _rng := RandomNumberGenerator.new()
var _profile: Dictionary
var _table: Node2D
var _balls: Node
var _plunger: Node
## El autoload GameState (se busca en el árbol: con `-s` no existe como identificador al compilar).
var _game: Node
var _aim: Aim
## Cada flipper: {node, action, dir, pivot, length, rest, pressed, release_at, cooldown, mode, ...}.
var _flippers: Array[Dictionary] = []
var _clock := 0.0
var _sample_clock := 0.0
## Fotos de las bolas en juego: {t, balls: [{pos, vel}]}.
var _history: Array[Dictionary] = []
var _plan_clock := 0.0
var _launch_wait := 0.0
var _launch_time := 0.7
var _launching := false
var _random_clock := 0.0
var _random_hold := 0.0
var _nudge_ready_at := 0.0


func _init(new_skill: String, table: Node2D, seed_value: int) -> void:
	skill = new_skill
	_profile = PROFILES.get(skill, {}).duplicate()
	# Para afinar niveles sin tocar el código: PLAYTEST_TUNE='{"lead": 0.9}' pisa parámetros del perfil.
	var tune := OS.get_environment("PLAYTEST_TUNE")
	if not tune.is_empty() and JSON.parse_string(tune) is Dictionary:
		_profile.merge(JSON.parse_string(tune), true)
	_table = table
	_balls = table.get_node("Balls")
	_plunger = table.get_node("Plunger")
	_game = table.get_tree().root.get_node("GameState")
	_aim = Aim.new(table)
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
			"mode": "hit",
			"settle": 0.0,
			"press_at": 0.0,
			"jitter": 0.0,
			"catch_roll": 1.0,
			"aim_a": 0.0,
			"aim_at": -1.0,
			"plan": {},
		})
		if skill != "azar":
			_roll_shot(_flippers[_flippers.size() - 1])
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
	var fresh := _sample(delta)
	_tick_launch(delta)
	var observed := _observed()
	if fresh:
		_plan(observed)
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

## Toma una foto cada SAMPLE_STEP. Devuelve true si tomó una nueva.
func _sample(delta: float) -> bool:
	_sample_clock += delta
	if _sample_clock < SAMPLE_STEP:
		return false
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
	return true


## Lo que el bot "ve" ahora: la foto de hace `reaction` segundos, con la posición extrapolada (con
## gravedad) la fracción `lead` del atraso.
func _observed() -> Array:
	if _history.is_empty():
		return []
	var snap: Dictionary = _history[0]
	var age := (_clock - float(snap.t)) * float(_profile.lead)
	var result: Array = []
	for b in snap.balls:
		var vel: Vector2 = b.vel + Vector2(0.0, GRAVITY * age)
		result.append({"pos": b.pos + b.vel * age + Vector2(0.0, 0.5 * GRAVITY * age * age), "vel": vel})
	return result


# --- Predicción -----------------------------------------------------------------------------------

## Por flipper, la bola que antes va a hacer contacto con la paleta en reposo (`plan`: {t, along, speed}).
func _plan(observed: Array) -> void:
	_plan_clock = _clock
	for f in _flippers:
		var best := {}
		for b in observed:
			var hit := _predict(f, b)
			if not hit.is_empty() and (best.is_empty() or hit.t < best.t):
				best = hit
		f.plan = best


## Balística con gravedad hasta tocar la línea de la paleta en reposo dentro de su largo.
func _predict(f: Dictionary, b: Dictionary) -> Dictionary:
	var pos: Vector2 = b.pos
	var vel: Vector2 = b.vel
	var slope := tan(deg_to_rad(f.rest))
	var t := 0.0
	while t <= PREDICT_HORIZON:
		var rel: Vector2 = pos - f.pivot
		var along: float = rel.x * f.dir
		var height: float = along * slope - rel.y
		if along > -8.0 and along < f.length + 22.0:
			if height <= CONTACT_HEIGHT and height > -22.0:
				return {"t": t, "along": along, "speed": vel.length()}
		elif pos.y > f.pivot.y + 70.0:
			return {}
		vel.y += GRAVITY * PREDICT_STEP
		pos += vel * PREDICT_STEP
		t += PREDICT_STEP
	return {}


# --- Flippers -------------------------------------------------------------------------------

func _set_pressed(f: Dictionary, pressed: bool) -> void:
	if f.pressed == pressed:
		return
	f.pressed = pressed
	if pressed:
		Input.action_press(f.action)
	else:
		Input.action_release(f.action)


## Sortea lo que el bot piensa hacer con la próxima bola de este flipper: a qué punto de la paleta
## pegarle, si la atrapa y cuánto se equivoca en el timing.
func _roll_shot(f: Dictionary) -> void:
	f.jitter = _rng.randfn(0.0, float(_profile.timing))
	f.catch_roll = _rng.randf()
	f.aim_a = _pick_aim(f)
	f.aim_at = _clock + AIM_REFRESH


## Ángulo (grados) de salida para una bola que se golpea a `along` px del pivote (interpolado).
func _angle_at(along: float) -> float:
	if along <= AIM_ALONG[0]:
		return AIM_ANGLE[0]
	for i in range(1, AIM_ALONG.size()):
		if along <= AIM_ALONG[i]:
			var k: float = (along - AIM_ALONG[i - 1]) / (AIM_ALONG[i] - AIM_ALONG[i - 1])
			return lerpf(AIM_ANGLE[i - 1], AIM_ANGLE[i], k)
	return AIM_ANGLE[AIM_ANGLE.size() - 1]


## Punto de la paleta (px desde el pivote) donde conviene pegarle a una bola lenta: el que mejor
## manda la bola a los blancos encendidos. Los niveles bajos a veces no apuntan a nada.
func _pick_aim(f: Dictionary) -> float:
	var length: float = f.length
	var max_a := length - 8.0
	if _rng.randf() >= float(_profile.aim_p):
		return _rng.randf_range(0.45, 0.95) * length
	var targets := _aim.wanted()
	var best_a := 0.6 * length
	var best_score := -1.0
	var a := 12.0
	while a <= max_a:
		var angle := deg_to_rad(_angle_at(a))
		var x0: float = f.pivot.x + f.dir * a * cos(deg_to_rad(f.rest))
		var y0: float = f.pivot.y + a * sin(deg_to_rad(f.rest))
		var score := 0.0
		for t in targets:
			var dy: float = y0 - t.pos.y
			if dy < 60.0:
				continue
			var x_at: float = x0 + f.dir * tan(angle) * dy
			var miss: float = (x_at - t.pos.x) / 42.0
			score += float(t.w) * exp(-miss * miss)
		if score > best_score:
			best_score = score
			best_a = a
		a += 3.0
	return clampf(best_a + _rng.randfn(0.0, float(_profile.aim_error)), 14.0, max_a)


## ¿Hay una bola casi quieta apoyada en la paleta alzada?
func _settled(f: Dictionary, observed: Array) -> bool:
	var slope := tan(f.node.rotation * f.dir)
	for b in observed:
		var rel: Vector2 = b.pos - f.pivot
		var along: float = rel.x * f.dir
		var height: float = along * slope - rel.y
		if along > -5.0 and along < f.length and height > -6.0 and height < 48.0 and b.vel.length() < SETTLED_SPEED:
			return true
	return false


func _tick_flipper(f: Dictionary, observed: Array, delta: float) -> void:
	f.cooldown = maxf(0.0, f.cooldown - delta)
	if _game.tilted:
		_set_pressed(f, false)
		return
	if _clock >= f.aim_at:
		f.aim_a = _pick_aim(f)
		f.aim_at = _clock + AIM_REFRESH
	if f.pressed:
		if f.mode == "catch":
			f.settle = f.settle + delta if _settled(f, observed) else 0.0
			if f.settle < SETTLED_TIME and _clock < f.press_at + MAX_CATCH:
				return
		elif _clock < f.release_at:
			return
		_set_pressed(f, false)
		f.cooldown = 0.05
		f.mode = "hit"
		f.settle = 0.0
		_roll_shot(f)
		return
	if f.cooldown > 0.0 or f.plan.is_empty():
		return
	var plan: Dictionary = f.plan
	var ttc: float = float(plan.t) - (_clock - _plan_clock)
	var slow: bool = plan.speed < SLOW_SPEED
	if slow and skill != "novato":
		# Bola que rueda por la paleta: se espera al punto elegido (o al final, que se va).
		var lead_along: float = float(plan.speed) * PRESS_LEAD
		if plan.along + lead_along < minf(f.aim_a, f.length - 10.0):
			return
		if ttc > PRESS_LEAD:
			return
		_press(f, "hit", float(_profile.hold))
		return
	if f.catch_roll < float(_profile.catch_p) and not slow and plan.speed < float(_profile.get("catch_max", 600.0)):
		if ttc <= CATCH_LEAD:
			_press(f, "catch", MAX_CATCH)
		return
	if ttc <= PRESS_LEAD + f.jitter:
		_press(f, "hit", float(_profile.hold))


func _press(f: Dictionary, mode: String, hold: float) -> void:
	_set_pressed(f, true)
	f.mode = mode
	f.press_at = _clock
	f.release_at = _clock + hold
	f.settle = 0.0


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
		if b.pos.y > pivot_y - float(_profile.get("nudge_up", 10.0)) and outside and b.vel.y > 0.0:
			_nudge_ready_at = _clock + float(_profile.get("nudge_cd", NUDGE_COOLDOWN))
			var side := 1.0 if b.pos.x < left_x else -1.0
			_game.nudge(Vector2(side * 0.5, -1.0))
			return
