extends Node
## Reglas de Kernel Panic (S-05): procesos que se cargan, multibola `fork()` y jackpot `sudo`.
## Completar el banco de blancos (StandupBank) o los rollovers superiores (RolloverBank) "carga" un
## proceso; con `fork_processes_needed` procesos el saucer FORK queda listo y la bola que entra se
## bifurca en `fork_balls` bolas. Durante la multibola, girar el spinner `sudo_laps` vueltas enciende
## `sudo`; la próxima bola que entre al saucer cobra el jackpot. La multibola termina (segfault) al
## quedar una sola bola. Números y textos: TableRules (resources/rules/kernel_panic.tres).
## La partida guardada no lleva el estado de la regla: al reanudar con 2 o más bolas se retoma la multibola.

## Un proceso más cargado (`count` de `total`).
signal process_loaded(count: int, total: int)
signal fork_ready_changed(ready: bool)
signal multiball_started
signal multiball_ended
signal sudo_lit_changed(lit: bool)
signal jackpot_scored(award: int)

## Procesos cargados hacia el próximo fork() (0..fork_processes_needed).
var processes := 0
var fork_ready := false
var multiball := false
var sudo_lit := false
## Vueltas del spinner acumuladas hacia el próximo sudo.
var sudo_progress := 0

var _saucer: Node
var _spinner: Node
var _bank: Node
var _rollovers: Node
var _art: Node
var _main: Node
var _last_spinner_laps := 0


func _rules() -> TableRules:
	return GameState.active_rules()


func _ready() -> void:
	var table := get_parent()
	_main = table.get_parent()
	_art = table.get_node_or_null("PlayfieldArt")
	_saucer = table.get_node_or_null("KernelLayout/Fork")
	_spinner = table.get_node_or_null("KernelLayout/Sudo")
	_bank = table.get_node_or_null("KernelLayout/StandupBank")
	_rollovers = table.get_node_or_null("KernelLayout/RolloverBank")
	if _saucer:
		_saucer.kicked.connect(_on_saucer_kicked)
	if _spinner:
		_spinner.lap_completed.connect(_on_spinner_lap)
	if _bank:
		_bank.completed.connect(_on_bank_completed)
	if _rollovers:
		_rollovers.completed.connect(_on_bank_completed)
	GameState.game_started.connect(reset)
	GameState.game_resumed.connect(_on_game_resumed)
	set_physics_process(false)


## Partida nueva: todo vuelve a cero (las bolas las borra main.gd).
func reset() -> void:
	var was_multiball := multiball
	multiball = false
	processes = 0
	sudo_progress = 0
	_last_spinner_laps = _spinner.laps if _spinner else 0
	_set_fork_ready(false)
	_set_sudo_lit(false)
	set_physics_process(false)
	if was_multiball:
		multiball_ended.emit()


func _physics_process(_delta: float) -> void:
	# La multibola termina cuando queda una sola bola en juego.
	if multiball and GameState.playing and _ball_count() <= 1:
		_end_multiball()


func _ball_count() -> int:
	return _main.ball_count() if _main and _main.has_method("ball_count") else 0


func _on_bank_completed(_award: int) -> void:
	if not GameState.playing or multiball or fork_ready:
		return
	var total := _rules().fork_processes_needed
	processes = mini(processes + 1, total)
	process_loaded.emit(processes, total)
	if processes >= total:
		_set_fork_ready(true)
		GameState.say(_rules().text("fork_ready"))
	else:
		GameState.say(_rules().text("process_loaded", {"count": processes, "total": total}))


## Enciende o apaga el aro dorado del saucer y avisa si cambió `fork_ready`.
func _set_fork_ready(ready: bool) -> void:
	var changed := fork_ready != ready
	fork_ready = ready
	_set_saucer_lit(ready)
	if changed:
		fork_ready_changed.emit(ready)


func _set_sudo_lit(lit: bool) -> void:
	var changed := sudo_lit != lit
	sudo_lit = lit
	if _spinner:
		_spinner.lit = lit
		_spinner.queue_redraw()
	if changed:
		sudo_lit_changed.emit(lit)


func _set_saucer_lit(lit: bool) -> void:
	if _saucer:
		_saucer.lit = lit
		_saucer.queue_redraw()


func _on_spinner_lap(total: int) -> void:
	var gained := total - _last_spinner_laps
	_last_spinner_laps = total
	if not multiball or sudo_lit or not GameState.playing:
		return
	sudo_progress += gained
	if sudo_progress >= _rules().sudo_laps:
		_set_sudo_lit(true)
		_set_saucer_lit(true)
		GameState.say(_rules().text("sudo_lit"))


## La bola ya salió del saucer: es el momento de bifurcar o de cobrar el jackpot.
func _on_saucer_kicked(ball: Node) -> void:
	if not GameState.playing:
		return
	if multiball:
		if sudo_lit:
			_pay_jackpot(_saucer.global_position)
	elif fork_ready:
		start_multiball(ball)


## Empieza la multibola `fork()`. Sin `source` bifurca desde el saucer (lo usa el modo de pruebas, Q-02).
func start_multiball(source: Node = null) -> void:
	if multiball:
		return
	multiball = true
	processes = 0
	sudo_progress = 0
	_last_spinner_laps = _spinner.laps if _spinner else 0
	_set_fork_ready(false)
	_set_sudo_lit(false)
	var table := _main.get_node("Table")
	var origin := Vector2(336, 250)
	if _saucer:
		origin = table.to_local(_saucer.global_position)
	if source is Node2D:
		origin = table.to_local((source as Node2D).global_position)
	var missing := _rules().fork_balls - _ball_count()
	for i in maxi(missing, 0):
		var side := -1.0 if i % 2 == 0 else 1.0
		_main._spawn_ball(origin + Vector2(side * 36.0, 28.0), Vector2(side * 220.0, 420.0))
	set_physics_process(true)
	GameState.say(_rules().text("fork_start"))
	Sfx.play(&"jackpot")
	multiball_started.emit()


func _end_multiball() -> void:
	multiball = false
	sudo_progress = 0
	_set_sudo_lit(false)
	_set_saucer_lit(false)
	set_physics_process(false)
	GameState.say(_rules().text("fork_end"))
	multiball_ended.emit()


func _pay_jackpot(at: Vector2) -> void:
	var stage := _rules().sudo_jackpot
	GameState.register_jackpot()
	GameState.add_score(stage.award, at)
	if stage.raise_multiplier:
		GameState.raise_multiplier(false)
	if not stage.message.is_empty():
		GameState.say(TableRules.fill(stage.message, {"award": stage.award, "bonus": GameState.bonus_multiplier}))
	sudo_progress = 0
	_last_spinner_laps = _spinner.laps if _spinner else 0
	_set_sudo_lit(false)
	_set_saucer_lit(false)
	if _art and _art.has_method("flash_jackpot"):
		_art.flash_jackpot()
	Sfx.play(&"jackpot")
	jackpot_scored.emit(stage.award)


## Al reanudar una partida guardada con varias bolas en juego, la multibola sigue.
func _on_game_resumed() -> void:
	if _ball_count() >= 2 and not multiball:
		multiball = true
		set_physics_process(true)
		GameState.say(_rules().text("fork_resumed"))
		multiball_started.emit()
