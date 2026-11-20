extends Node
## Estado global de la partida: puntaje, bolas restantes y récord.
## Las piezas de la mesa llaman a add_score(); el HUD escucha las señales.

signal score_changed(score: int)
signal scored(points: int, world_position: Vector2)
signal balls_changed(balls_left: int)
signal message(text: String)
signal game_started
signal game_ended(final_score: int, is_record: bool)

const BALLS_PER_GAME := 3
const KERNEL_PANIC := "kernel_panic"
const NAUTILUS := "nautilus"
## Variable (no const) para que los tests usen un archivo propio.
var record_path := "user://records.cfg"

## Teclas y botones por defecto. El touch también pasa por estas acciones,
## así que los flippers leen siempre lo mismo venga de donde venga.
const DEFAULT_KEYS := {
	"flipper_left": [KEY_Z, KEY_LEFT, KEY_A],
	"flipper_right": [KEY_M, KEY_RIGHT, KEY_L],
	"launch": [KEY_SPACE, KEY_DOWN, KEY_ENTER],
	"pause": [KEY_ESCAPE, KEY_P],
}
const DEFAULT_JOY_BUTTONS := {
	"flipper_left": [JOY_BUTTON_LEFT_SHOULDER],
	"flipper_right": [JOY_BUTTON_RIGHT_SHOULDER],
	"launch": [JOY_BUTTON_A],
	"pause": [JOY_BUTTON_START],
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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_default_inputs()
	_load_record()


func start_game() -> void:
	score = 0
	balls_left = BALLS_PER_GAME
	ball_in_lane = false
	plunger_charge = 0.0
	playing = true
	score_changed.emit(score)
	balls_changed.emit(balls_left)
	game_started.emit()


func select_table(id: String) -> void:
	if table_id != id:
		table_id = id
		_load_record()


func leave_game() -> void:
	playing = false
	ball_in_lane = false
	plunger_charge = 0.0


func add_score(points: int, world_position: Vector2) -> void:
	if not playing:
		return
	score += points
	scored.emit(points, world_position)
	score_changed.emit(score)


## Resta una bola. Devuelve true si la partida sigue.
func lose_ball() -> bool:
	balls_left -= 1
	balls_changed.emit(balls_left)
	if balls_left <= 0:
		end_game()
		return false
	return true


func end_game() -> void:
	playing = false
	var is_record := score > high_score
	if is_record:
		high_score = score
		_save_record()
	game_ended.emit(score, is_record)


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
