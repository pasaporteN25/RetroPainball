extends Node
## G-06: banco de blancos. Recuerda cuáles fueron golpeados; al completarlos todos
## otorga un premio, sube el multiplicador del bonus y se reinicia.

## Se emite al completar el banco (para engancharle arte o sonido).
signal completed(award: int)

@export var members: Array[NodePath] = []
@export var award := 1000

var _targets: Array = []


func _ready() -> void:
	for path in members:
		var target := get_node_or_null(path)
		if target != null and target.has_signal("hit"):
			_targets.append(target)
			target.hit.connect(_on_target_hit)


func hit_count() -> int:
	var count := 0
	for target in _targets:
		if target.activated:
			count += 1
	return count


func _on_target_hit() -> void:
	if _targets.is_empty() or hit_count() < _targets.size():
		return
	var at: Vector2 = _targets[0].global_position
	GameState.add_score.call_deferred(award, at)
	GameState.raise_multiplier()
	reset()
	completed.emit(award)


## Vuelve a dejar todos los blancos sin activar.
func reset() -> void:
	for target in _targets:
		target.set_activated(false)
