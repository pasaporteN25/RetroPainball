extends Node
## G-05: rollovers superiores. Cada carril cruzado queda encendido; los flippers rotan
## los encendidos (izquierda hacia la izquierda, derecha hacia la derecha). Con todos
## encendidos se da un premio, sube el multiplicador del bonus y se reinicia.

## Se emite al completar los carriles (para engancharle arte o sonido).
signal completed(award: int)

@export var members: Array[NodePath] = []
## Premio de los carriles completos; -1 = TableRules.rollover_award. Leer `award` da el valor efectivo.
@export var award_override := -1
var award: int:
	get:
		return award_override if award_override >= 0 else GameState.active_rules().rollover_award

var _lanes: Array = []


func _ready() -> void:
	for path in members:
		var lane := get_node_or_null(path)
		if lane != null and lane.has_signal("crossed"):
			_lanes.append(lane)
			lane.crossed.connect(_on_lane_crossed)
	# De izquierda a derecha, que es el orden en que rotan.
	_lanes.sort_custom(func(a, b): return a.position.x < b.position.x)


func _physics_process(_delta: float) -> void:
	# Se consulta la acción (no el evento) para que sirva también con los botones táctiles.
	if not GameState.playing:
		return
	if Input.is_action_just_pressed(&"flipper_left"):
		rotate_lit(-1)
	if Input.is_action_just_pressed(&"flipper_right"):
		rotate_lit(1)


func lit_count() -> int:
	var count := 0
	for lane in _lanes:
		if lane.lit:
			count += 1
	return count


## Rota los carriles encendidos: -1 hacia la izquierda, +1 hacia la derecha (con vuelta).
func rotate_lit(direction: int) -> void:
	var count := _lanes.size()
	if count < 2:
		return
	var old: Array[bool] = []
	for lane in _lanes:
		old.append(lane.lit)
	for i in count:
		_lanes[i].set_lit(old[posmod(i - direction, count)])


func _on_lane_crossed() -> void:
	if _lanes.is_empty() or lit_count() < _lanes.size():
		return
	GameState.add_score.call_deferred(award, _lanes[0].global_position)
	GameState.raise_multiplier()
	reset()
	completed.emit(award)


## Apaga todos los carriles.
func reset() -> void:
	for lane in _lanes:
		lane.set_lit(false)
