extends Node
## Reglas de la mesa Drácula (S-07): banco de murciélagos, órbita Carfax, ataúd con lock y Medianoche.
## Las piezas (Bats, Carfax, Coffin, Portrait) solo avisan y dibujan; los puntajes y el estado viven acá.
## El contrato con el arte está en docs/mesas/DRACULA.md.

signal bats_changed(hit: int)
signal lock_lit_changed(lit: bool)
signal ball_locked(count: int)
signal midnight_started
signal midnight_ended
## Vuelta Carfax puntuada: 0 = primera (500), 1 = segunda (1000), 2 = tercera (1500 y multiplicador).
signal carfax_scored(stage: int)

## Puntajes, umbrales y textos: salen de TableRules (resources/rules/dracula.tres), ver `_rules()`.

var locks_lit := false
var locked_balls := 0
var midnight := false
var bats_hit := 0
## Vueltas Carfax cumplidas del ciclo (0..2): la próxima vuelta puntúa `carfax_stages[carfax_stage]` de TableRules.
var carfax_stage := 0

var _bats: Array[Node] = []
var _carfax: Node
var _coffin: Node
var _portrait: Node
var _art: Node
var _main: Node


func _rules() -> TableRules:
	return GameState.active_rules()


func _ready() -> void:
	var table := get_parent()
	_main = table.get_parent()
	_art = table.get_node_or_null("PlayfieldArt")
	var bats := table.get_node_or_null("Bats")
	if bats:
		for bat in bats.get_children():
			_bats.append(bat)
			bat.hit.connect(_on_bat_hit)
	_carfax = table.get_node_or_null("Carfax")
	if _carfax:
		_carfax.completed.connect(_on_carfax_completed)
	_coffin = table.get_node_or_null("Coffin")
	if _coffin:
		_coffin.ball_locked.connect(_on_ball_locked)
	_portrait = table.get_node_or_null("Portrait")
	if _portrait:
		_portrait.struck.connect(_on_portrait_struck)
	GameState.game_started.connect(reset)
	set_physics_process(false)


## Partida nueva: todo vuelve a cero (las bolas las borra main.gd).
func reset() -> void:
	var was_midnight := midnight
	midnight = false
	locked_balls = 0
	locks_lit = false
	bats_hit = 0
	carfax_stage = 0
	for bat in _bats:
		bat.set_activated(false)
	if _coffin:
		_coffin.reset()
	if _carfax:
		_carfax.set_stage(0)
	if _portrait:
		_portrait.jackpot_ready = false
	set_physics_process(false)
	bats_changed.emit(0)
	lock_lit_changed.emit(false)
	ball_locked.emit(0)
	if was_midnight:
		midnight_ended.emit()


func _physics_process(_delta: float) -> void:
	# La Medianoche termina cuando queda una sola bola en juego.
	if midnight and GameState.playing and _ball_count() <= 1:
		_end_midnight()


func _ball_count() -> int:
	return _main.ball_count() if _main and _main.has_method("ball_count") else 0


func _on_bat_hit() -> void:
	if not GameState.playing:
		return
	var count := 0
	for bat in _bats:
		if bat.activated:
			count += 1
	bats_hit = count
	bats_changed.emit(bats_hit)
	if count < _bats.size() or _bats.is_empty():
		return
	GameState.add_score(_rules().bat_bank_award, _bats[int(_bats.size() / 2.0)].global_position)
	GameState.raise_multiplier(false)
	for bat in _bats:
		bat.set_activated(false)
	bats_hit = 0
	bats_changed.emit(0)
	if not midnight and not locks_lit and locked_balls < _rules().locks_for_midnight:
		_set_lock_lit(true)
		GameState.say(_rules().text("lock_lit"))
	else:
		GameState.say(_rules().text("bats_bonus", {"bonus": GameState.bonus_multiplier}))


func _set_lock_lit(lit: bool) -> void:
	locks_lit = lit
	if _coffin:
		_coffin.lock_lit = lit
	lock_lit_changed.emit(lit)


func _on_carfax_completed(at: Vector2) -> void:
	if not GameState.playing:
		return
	var stages := _rules().carfax_stages
	if stages.is_empty():
		return
	var stage := carfax_stage
	var lap := stages[stage]
	GameState.add_score(lap.award, at)
	carfax_scored.emit(stage)
	var last := stage == stages.size() - 1
	carfax_stage = 0 if last else stage + 1
	if lap.raise_multiplier:
		GameState.raise_multiplier(false)
	if not lap.message.is_empty():
		GameState.say(TableRules.fill(lap.message, {"stage": stage + 1,
			"total": stages.size(), "bonus": GameState.bonus_multiplier, "award": lap.award}))
	if _carfax:
		_carfax.set_stage(carfax_stage)


func _on_ball_locked(_ball: Node) -> void:
	locked_balls += 1
	_set_lock_lit(false)
	GameState.add_score(_rules().lock_points, _coffin.global_position)
	ball_locked.emit(locked_balls)
	# Sale una bola nueva al carril (si no hay ya una esperando).
	if _main and _main.has_method("serve_ball") and not GameState.ball_in_lane:
		_main.serve_ball()
	if locked_balls >= _rules().locks_for_midnight:
		_start_midnight()
	else:
		GameState.say(_rules().text("ball_locked"))


## Empieza la Medianoche sin tener que encerrar bolas (lo usa el modo de pruebas, Q-02).
func start_midnight() -> void:
	if not midnight:
		_start_midnight()


func _start_midnight() -> void:
	midnight = true
	_coffin.release_locked()
	locked_balls = 0
	ball_locked.emit(0)
	if _portrait:
		_portrait.jackpot_ready = true
	set_physics_process(true)
	GameState.say(_rules().text("midnight_start"))
	midnight_started.emit()


func _end_midnight() -> void:
	midnight = false
	if _portrait:
		_portrait.jackpot_ready = false
	set_physics_process(false)
	GameState.say(_rules().text("midnight_end"))
	midnight_ended.emit()


## Si solo quedan bolas encerradas (la bola libre se perdió) se las libera para no trabar la partida.
func release_locked_balls() -> void:
	if locked_balls == 0 or not _coffin:
		return
	_coffin.release_locked()
	locked_balls = 0
	ball_locked.emit(0)
	GameState.say(_rules().text("balls_released"))


func _on_portrait_struck(at: Vector2) -> void:
	if not GameState.playing:
		return
	if not midnight:
		GameState.add_score(_rules().portrait_points, at)
		return
	var jackpot := _rules().midnight_jackpot_points
	GameState.add_score(jackpot, at)
	GameState.say(_rules().text("jackpot", {"award": jackpot}))
	if _art and _art.has_method("flash_jackpot"):
		_art.flash_jackpot()
