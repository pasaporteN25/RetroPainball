extends Node
## Estado global de la partida: puntaje, bolas restantes y récord.
## Las piezas de la mesa llaman a add_score(); el HUD escucha las señales.

signal score_changed(score: int)
signal scored(points: int, world_position: Vector2)
signal balls_changed(balls_left: int)
signal message(text: String)
signal game_started
signal game_resumed
signal game_ended(final_score: int, is_record: bool)
## Al perder una bola: bonus acumulado, multiplicador y puntos otorgados.
signal bonus_awarded(base: int, multiplier: int, total: int)
## Un empujón válido: la mesa le da un impulso a las bolas en juego.
signal nudged(direction: Vector2)
signal tilt_changed(tilted: bool)
## G-12: cambió el kickback (rearmado o gastado) o las bolas extra pendientes.
signal kickback_changed(ready: bool)
signal extra_balls_changed(extra_balls: int)
## Se perdió la bola en juego (antes de cobrar el bonus): las mesas con estado por bola lo reinician.
signal ball_lost

const BALLS_PER_GAME := 3
## Fracción de cada puntaje que se acumula en el bonus de la bola.
const BONUS_RATE := 0.1
const MAX_MULTIPLIER := 5
## Bolas extra que se pueden ganar en una partida y acumular a la vez (G-12).
const MAX_EXTRA_AWARDS := 1
const MAX_PENDING_EXTRA := 2
const KERNEL_PANIC := "kernel_panic"
const NAUTILUS := "nautilus"
const DRACULA := "dracula"
const ALICIA := "alicia"
const Tilt := preload("res://scripts/table/tilt.gd")
const Records := preload("res://scripts/util/records.gd")
const TableStats := preload("res://scripts/util/table_stats.gd")
## Variable (no const) para que los tests usen un archivo propio.
var record_path := "user://records.cfg"
## Vacío desactiva los guardados, por ejemplo al probar la física.
var save_directory := "user://saved_games"

## Teclas y botones por defecto. El touch también pasa por estas acciones,
## así que los flippers leen siempre lo mismo venga de donde venga.
const DEFAULT_KEYS := {
	"flipper_left": [KEY_Z, KEY_LEFT, KEY_A],
	"flipper_right": [KEY_M, KEY_RIGHT, KEY_L],
	"launch": [KEY_SPACE, KEY_DOWN, KEY_ENTER],
	"pause": [KEY_ESCAPE, KEY_P],
	"nudge": [KEY_N],
}
const DEFAULT_JOY_BUTTONS := {
	"flipper_left": [JOY_BUTTON_LEFT_SHOULDER],
	"flipper_right": [JOY_BUTTON_RIGHT_SHOULDER],
	"launch": [JOY_BUTTON_A],
	"pause": [JOY_BUTTON_START],
	"nudge": [JOY_BUTTON_Y],
}

var score := 0
var balls_left := BALLS_PER_GAME
var high_score := 0
var playing := false
var table_id := KERNEL_PANIC
## Lo actualiza el lanzador: true si hay una bola esperando en el carril.
var ball_in_lane := false
## Carga del lanzador (0..1), para mostrarla en el botón de lanzar.
var plunger_charge := 0.0
## Bonus de la bola en juego y su multiplicador; se cobran al perder la bola.
var bonus := 0
var bonus_multiplier := 1
## Puntos del último bonus cobrado (0 si no hubo), para que la mesa espere el aviso.
var last_bonus_award := 0
## G-12: el kickback se gasta una vez por bola y se rearma al empezar la bola siguiente.
var kickback_ready := true
## Bolas extra pendientes (la próxima bola perdida se repite sin gastar una) y cuántas se dieron.
var extra_balls := 0
var extra_awarded := 0
## true si la última bola perdida se repitió por una bola extra.
var last_ball_replayed := false
## Calor de nudge/tilt (G-04). En TILT los flippers no responden y el bonus se pierde.
var tilt := Tilt.new()
## Variante del top 10 (p. ej. la dificultad). Vacía = un solo top por mesa.
var record_variant := ""
## Puntos de la bola en juego, mejor bola de la partida y jackpots cobrados (U-09).
var ball_points := 0
var best_ball := 0
var jackpots := 0
## Bonus cobrado en total durante la partida (se muestra al terminar).
var bonus_total := 0
## Resultado de la última partida terminada (U-05, U-06).
## Claves: score, bonus_total, rank (0 = no entra al top), key, table_id.
var last_result := {}
var tilted: bool:
	get:
		return tilt.tilted


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_default_inputs()
	_load_record()


func _process(delta: float) -> void:
	if not playing or get_tree().paused:
		return
	tilt.tick(delta)
	if tilt.feed_accelerometer(Input.get_accelerometer()):
		nudge(Vector2(randf_range(-0.4, 0.4), -1.0))
	elif Input.is_action_just_pressed("nudge"):
		nudge(Vector2(randf_range(-0.6, 0.6), -1.0))


func start_game() -> void:
	_set_active_run(0, BALLS_PER_GAME)
	game_started.emit()


func resume_game(saved_score: int, saved_balls_left: int, saved_bonus := 0, saved_multiplier := 1,
		saved_extra := 0, saved_awarded := 0, saved_kickback := true) -> void:
	_set_active_run(saved_score, saved_balls_left)
	bonus = maxi(saved_bonus, 0)
	bonus_multiplier = clampi(saved_multiplier, 1, MAX_MULTIPLIER)
	extra_balls = clampi(saved_extra, 0, MAX_PENDING_EXTRA)
	extra_awarded = clampi(saved_awarded, 0, MAX_EXTRA_AWARDS)
	kickback_ready = saved_kickback
	game_resumed.emit()


func _set_active_run(new_score: int, new_balls_left: int) -> void:
	score = new_score
	balls_left = new_balls_left
	bonus = 0
	bonus_multiplier = 1
	last_bonus_award = 0
	bonus_total = 0
	ball_points = 0
	best_ball = 0
	jackpots = 0
	extra_balls = 0
	extra_awarded = 0
	last_ball_replayed = false
	kickback_ready = true
	_reset_tilt()
	ball_in_lane = false
	plunger_charge = 0.0
	playing = true
	score_changed.emit(score)
	balls_changed.emit(balls_left)


## Tema (colores, textos, fuente) de la mesa activa o de la mesa `id` (S-01).
func active_theme(id := "") -> TableTheme:
	return TableTheme.for_table(id if not id.is_empty() else table_id)


## Reglas (puntajes, objetivos, tiempos, mensajes) de la mesa activa o de la mesa `id` (S-03).
func active_rules(id := "") -> TableRules:
	return TableRules.for_table(id if not id.is_empty() else table_id)


func select_table(id: String) -> void:
	if table_id != id:
		table_id = id
		_load_record()


func leave_game() -> void:
	playing = false
	_reset_tilt()
	ball_in_lane = false
	plunger_charge = 0.0


func add_score(points: int, world_position: Vector2) -> void:
	if not playing:
		return
	score += points
	ball_points += points
	bonus += int(points * BONUS_RATE)
	scored.emit(points, world_position)
	score_changed.emit(score)


## Sube un escalón el multiplicador del bonus (lo llaman las misiones de cada mesa).
func raise_multiplier(announce := true) -> void:
	if not playing or bonus_multiplier >= MAX_MULTIPLIER:
		return
	bonus_multiplier += 1
	if announce:
		say("BONUS X%d" % bonus_multiplier)
	# Hito del bonus: llegar al multiplicador máximo regala una bola extra (una por partida).
	if bonus_multiplier >= MAX_MULTIPLIER and extra_awarded < MAX_EXTRA_AWARDS:
		award_extra_ball()


## Otorga una bola extra: la próxima bola que se pierda se repite sin gastar una de la partida.
## Devuelve false si no hay partida o ya hay el máximo pendiente.
func award_extra_ball(announce := true) -> bool:
	if not playing or extra_balls >= MAX_PENDING_EXTRA:
		return false
	extra_balls += 1
	extra_awarded = mini(extra_awarded + 1, MAX_EXTRA_AWARDS)
	extra_balls_changed.emit(extra_balls)
	if announce:
		say("¡BOLA EXTRA!")
	return true


## Gasta el kickback si está listo. Devuelve true si la bola debe ser devuelta.
func use_kickback() -> bool:
	if not playing or not kickback_ready:
		return false
	kickback_ready = false
	kickback_changed.emit(false)
	return true


func rearm_kickback() -> void:
	if not kickback_ready:
		kickback_ready = true
		kickback_changed.emit(true)


## Cobra el bonus acumulado y lo reinicia para la bola siguiente.
## En TILT el bonus se pierde sin cobrarse.
func award_bonus() -> int:
	var base := bonus
	var multiplier := bonus_multiplier
	bonus = 0
	bonus_multiplier = 1
	if tilted:
		last_bonus_award = 0
		if base > 0:
			say("TILT: SIN BONUS")
		return 0
	last_bonus_award = base * multiplier
	if last_bonus_award > 0:
		score += last_bonus_award
		bonus_total += last_bonus_award
		score_changed.emit(score)
		bonus_awarded.emit(base, multiplier, last_bonus_award)
		say("BONUS %d X%d" % [base, multiplier])
	return last_bonus_award


## Resta una bola. Devuelve true si la partida sigue.
func lose_ball() -> bool:
	ball_lost.emit()
	best_ball = maxi(best_ball, ball_points)
	ball_points = 0
	award_bonus()
	_reset_tilt()
	rearm_kickback()
	last_ball_replayed = false
	if extra_balls > 0:
		# Bola extra: se repite la bola y balls_left no baja.
		extra_balls -= 1
		last_ball_replayed = true
		extra_balls_changed.emit(extra_balls)
		return true
	balls_left -= 1
	balls_changed.emit(balls_left)
	if balls_left <= 0:
		end_game()
		return false
	return true


## Un empujón (deslizar hacia arriba, sacudir o la tecla N). `direction` apunta hacia donde
## sale la bola. Suma calor: avisa con poco y, con mucho, es TILT.
func nudge(direction: Vector2) -> void:
	if not playing or get_tree().paused:
		return
	match tilt.register_nudge():
		Tilt.Result.NUDGE:
			nudged.emit(direction)
		Tilt.Result.WARNING:
			nudged.emit(direction)
			say("CUIDADO")
		Tilt.Result.TILT:
			say("TILT")
			tilt_changed.emit(true)


func _reset_tilt() -> void:
	var was_tilted := tilt.tilted
	tilt.reset()
	if was_tilted:
		tilt_changed.emit(false)


func end_game() -> void:
	playing = false
	best_ball = maxi(best_ball, ball_points)
	ball_points = 0
	TableStats.add_game(record_path, table_id, best_ball, jackpots)
	var is_record := score > high_score
	if is_record:
		high_score = score
		_save_record()
	var key := records_key()
	# El puntaje se guarda solo, sin nombre ni pasos extra (U-05).
	var rank := Records.add(record_path, key, score)
	last_result = {"score": score, "bonus_total": bonus_total, "rank": rank, "key": key, "table_id": table_id}
	game_ended.emit(score, is_record)


## Las mesas avisan cada jackpot cobrado, para las estadísticas.
func register_jackpot() -> void:
	jackpots += 1


## Estadísticas guardadas de una mesa (la actual si no se indica).
func table_stats(id := "") -> Dictionary:
	return TableStats.load_stats(record_path, id if not id.is_empty() else table_id)


## Clave del top 10 de la mesa actual (y de la variante, si algún día hay dificultad).
func records_key() -> String:
	return Records.key(table_id, record_variant)


func top_scores(key := "") -> Array[Dictionary]:
	return Records.load_top(record_path, key if not key.is_empty() else records_key())


func say(text: String) -> void:
	message.emit(text)


func _register_default_inputs() -> void:
	for action: String in DEFAULT_KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		if not InputMap.action_get_events(action).is_empty():
			continue
		for key: int in DEFAULT_KEYS[action]:
			var kev := InputEventKey.new()
			kev.physical_keycode = key as Key
			InputMap.action_add_event(action, kev)
		for button: int in DEFAULT_JOY_BUTTONS.get(action, []):
			var jev := InputEventJoypadButton.new()
			jev.button_index = button as JoyButton
			InputMap.action_add_event(action, jev)


func _load_record() -> void:
	var cfg := ConfigFile.new()
	high_score = 0
	if cfg.load(record_path) == OK:
		high_score = int(cfg.get_value(_record_section(), "high_score", 0))


func _save_record() -> void:
	var cfg := ConfigFile.new()
	cfg.load(record_path)
	cfg.set_value(_record_section(), "high_score", high_score)
	cfg.save(record_path)


func _record_section() -> String:
	return "records" if table_id == KERNEL_PANIC else "records/" + table_id
