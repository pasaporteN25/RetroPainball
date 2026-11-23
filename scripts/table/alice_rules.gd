extends Node
## Reglas de la mesa Alicia (S-09): tamaño, banco de naipes, madriguera con lock, gato de Cheshire y Té Loco.
## Las piezas (Cards, Size, Cheshire, Rabbithole, Teapot) solo avisan y dibujan; puntajes y estado viven acá.
## El contrato con el arte está en docs/mesas/ALICIA.md. Todos los números y textos salen de TableRules.

signal size_changed(state: int)
signal card_flipped(index: int, mask: int)
signal cards_completed
signal lock_lit_changed(lit: bool)
signal ball_locked(count: int)
signal cheshire_changed(visible: bool)
signal cheshire_hit
signal tea_party_started
signal tea_party_ended

const SIZE_NORMAL := 0
const SIZE_SMALL := 1
const SIZE_BIG := 2

var size_state := SIZE_NORMAL
## Un bit por naipe (0..15).
var cards_mask := 0
var lock_lit := false
var locked_balls := 0
var tea_party := false
var cheshire_visible := true

var _cards: Array[Node] = []
var _drink: Node
var _eat: Node
var _cheshire: Node
var _hole: Node
var _teapot: Node
var _art: Node
var _main: Node
## Segundos que faltan para que el gato cambie de fase, y si ya se extendió en este ciclo.
var _cheshire_left := 0.0
var _extended := false


func _rules() -> TableRules:
	return GameState.active_rules()


func _ready() -> void:
	var table := get_parent()
	_main = table.get_parent()
	_art = table.get_node_or_null("PlayfieldArt")
	var cards := table.get_node_or_null("Cards")
	if cards:
		for card in cards.get_children():
			_cards.append(card)
			card.hit.connect(_on_card_hit)
	_drink = table.get_node_or_null("Size/DrinkMe")
	_eat = table.get_node_or_null("Size/EatMe")
	for target in [_drink, _eat]:
		if target:
			target.hit.connect(_on_size_target_hit)
	_cheshire = table.get_node_or_null("Cheshire")
	if _cheshire:
		_cheshire.struck.connect(_on_cheshire_struck)
	_hole = table.get_node_or_null("Rabbithole")
	if _hole:
		_hole.ball_locked.connect(_on_ball_locked)
		_hole.released.connect(_on_hole_released)
	_teapot = table.get_node_or_null("Teapot")
	if _teapot:
		_teapot.struck.connect(_on_teapot_struck)
	GameState.game_started.connect(reset)
	GameState.ball_lost.connect(_on_ball_lost)
	_cheshire_left = _rules().cheshire_visible_seconds


## Partida nueva: todo vuelve a cero (las bolas las borra main.gd).
func reset() -> void:
	var was_tea := tea_party
	tea_party = false
	locked_balls = 0
	lock_lit = false
	cards_mask = 0
	size_state = SIZE_NORMAL
	_extended = false
	_cheshire_left = _rules().cheshire_visible_seconds
	for i in _cards.size():
		_cards[i].set_flipped(false)
	if _hole:
		_hole.reset()
	_apply_size_visuals()
	_apply_lock()
	if _teapot:
		_teapot.jackpot_ready = false
	_set_cheshire(true)
	size_changed.emit(size_state)
	lock_lit_changed.emit(false)
	ball_locked.emit(0)
	if was_tea:
		tea_party_ended.emit()


func _physics_process(delta: float) -> void:
	tick(delta)


## Avanza el reloj del gato y vigila el fin de Té Loco. Público para poder probarlo sin esperar.
func tick(delta: float) -> void:
	if not GameState.playing:
		return
	if tea_party:
		if _ball_count() <= 1:
			_end_tea_party()
		return
	_cheshire_left -= delta
	if _cheshire_left <= 0.0:
		_set_cheshire(not cheshire_visible)


func _ball_count() -> int:
	return _main.ball_count() if _main and _main.has_method("ball_count") else 0


# --- Tamaño ---------------------------------------------------------------------------------------------

func _on_size_target_hit(kind: int) -> void:
	if not GameState.playing:
		return
	var wanted := SIZE_SMALL if kind == AliceVisuals.SIZE_DRINK else SIZE_BIG
	set_size(SIZE_NORMAL if size_state == wanted else wanted)


## Cambia el tamaño (paga y avisa). Público para el modo de pruebas y los tests.
func set_size(state: int) -> void:
	if state == size_state:
		return
	size_state = state
	var at := Vector2.ZERO
	var target := _drink if state == SIZE_SMALL else _eat
	if target:
		at = target.global_position
	GameState.add_score(_rules().size_change_points, at)
	GameState.say(_rules().text(["size_normal", "size_small", "size_big"][state]))
	_apply_size_visuals()
	_apply_lock()
	size_changed.emit(size_state)


func _apply_size_visuals() -> void:
	if _drink:
		_drink.active = size_state == SIZE_SMALL
	if _eat:
		_eat.active = size_state == SIZE_BIG


func _on_ball_lost() -> void:
	if size_state != SIZE_NORMAL:
		size_state = SIZE_NORMAL
		_apply_size_visuals()
		_apply_lock()
		size_changed.emit(size_state)


# --- Naipes ---------------------------------------------------------------------------------------------

func _on_card_hit(index: int) -> void:
	if not GameState.playing or index < 0 or index >= _cards.size():
		return
	var big := size_state == SIZE_BIG
	var points := _rules().card_points * (_rules().big_card_multiplier if big else 1)
	GameState.add_score(points, _cards[index].global_position)
	_flip(index)
	if big:
		# El naipe vecino que siga apagado: primero el de la derecha, si no el de la izquierda.
		for neighbor in [index + 1, index - 1]:
			if neighbor >= 0 and neighbor < _cards.size() and not _cards[neighbor].flipped:
				_flip(neighbor)
				break
	if cards_mask == (1 << _cards.size()) - 1:
		_complete_cards()


func _flip(index: int) -> void:
	_cards[index].set_flipped(true)
	cards_mask |= 1 << index
	card_flipped.emit(index, cards_mask)


func _complete_cards() -> void:
	var stage := _rules().card_bank
	GameState.add_score(stage.award, _cards[_cards.size() / 2].global_position)
	if stage.raise_multiplier:
		GameState.raise_multiplier(false)
	GameState.say(TableRules.fill(stage.message, {"bonus": GameState.bonus_multiplier, "award": stage.award}))
	cards_mask = 0
	for card in _cards:
		card.set_flipped(false)
	cards_completed.emit()
	if not tea_party and not lock_lit and locked_balls < _rules().locks_for_tea_party:
		_set_lock_lit(true)
		GameState.say(_rules().text("lock_lit"))


# --- Madriguera -----------------------------------------------------------------------------------------

func _set_lock_lit(lit: bool) -> void:
	lock_lit = lit
	_apply_lock()
	lock_lit_changed.emit(lit)


## La madriguera solo encierra con LOCK encendido y tamaño CHICA.
func _apply_lock() -> void:
	if _hole:
		_hole.lock_lit = lock_lit
		_hole.lock_armed = lock_lit and size_state == SIZE_SMALL


func _on_hole_released(at: Vector2) -> void:
	GameState.add_score(_rules().rabbithole_points, at)


func _on_ball_locked(_ball: Node) -> void:
	locked_balls += 1
	_set_lock_lit(false)
	GameState.add_score(_rules().alice_lock_points, _hole.global_position)
	ball_locked.emit(locked_balls)
	# Sale una bola nueva al carril (si no hay ya una esperando).
	if _main and _main.has_method("serve_ball") and not GameState.ball_in_lane:
		_main.serve_ball()
	if locked_balls >= _rules().locks_for_tea_party:
		_start_tea_party()
	else:
		GameState.say(_rules().text("ball_locked"))


## Si solo quedan bolas encerradas (la bola libre se perdió) se las libera para no trabar la partida.
func release_locked_balls() -> void:
	if locked_balls == 0 or not _hole:
		return
	_hole.release_locked()
	locked_balls = 0
	ball_locked.emit(0)
	GameState.say(_rules().text("balls_released"))


# --- Té Loco --------------------------------------------------------------------------------------------

## Empieza Té Loco sin encerrar bolas (lo usa el modo de pruebas, Q-02).
func start_tea_party() -> void:
	if not tea_party:
		_start_tea_party()


func _start_tea_party() -> void:
	tea_party = true
	if _hole:
		_hole.release_locked()
	locked_balls = 0
	ball_locked.emit(0)
	if _teapot:
		_teapot.jackpot_ready = true
	_set_cheshire(true)
	GameState.say(_rules().text("tea_start"))
	tea_party_started.emit()


func _end_tea_party() -> void:
	tea_party = false
	if _teapot:
		_teapot.jackpot_ready = false
	_cheshire_left = _rules().cheshire_visible_seconds
	_extended = false
	GameState.say(_rules().text("tea_end"))
	tea_party_ended.emit()


func _on_teapot_struck(at: Vector2) -> void:
	if not GameState.playing:
		return
	if not tea_party:
		GameState.add_score(_rules().teapot_points, at)
		return
	var stage := _rules().tea_jackpot
	GameState.add_score(stage.award, at)
	if stage.raise_multiplier:
		GameState.raise_multiplier(false)
	if not stage.message.is_empty():
		GameState.say(TableRules.fill(stage.message, {"award": stage.award, "bonus": GameState.bonus_multiplier}))
	if _art and _art.has_method("flash_jackpot"):
		_art.flash_jackpot()


# --- Gato de Cheshire -----------------------------------------------------------------------------------

func _set_cheshire(on: bool) -> void:
	_extended = false
	_cheshire_left = _rules().cheshire_visible_seconds if on else _rules().cheshire_hidden_seconds
	var changed := on != cheshire_visible
	cheshire_visible = on
	if _cheshire:
		_cheshire.set_shown(on)
	if changed:
		cheshire_changed.emit(on)


func _on_cheshire_struck(at: Vector2) -> void:
	if not GameState.playing or not cheshire_visible:
		return
	GameState.add_score(_rules().cheshire_points, at)
	cheshire_hit.emit()
	# Una vez por ciclo el golpe lo mantiene visible otros `cheshire_extend_seconds`.
	if not _extended and not tea_party:
		_extended = true
		_cheshire_left = _rules().cheshire_extend_seconds
