extends Node
## Misión de profundidad: tres sonares activan al kraken; golpear al kraken
## activo da el jackpot y baja un escalón de profundidad.
## El progreso sobrevive a la pérdida de bolas; solo reset() lo borra.

signal changed
signal jackpot

const SONAR_COUNT := 3
const DEPTH_STEP := 1500
const JACKPOT_POINTS := 5000
const SONAR_POINTS := 250
const KRAKEN_POINTS := 150

## Bits de los sonares ya marcados (bit i = sonar i).
var sonar_mask := 0
## Profundidad acumulada en metros.
var depth := 0


func reset() -> void:
	restore(0, 0)


func restore(mask: int, current_depth: int) -> void:
	sonar_mask = mask
	depth = current_depth
	changed.emit()


func is_kraken_active() -> bool:
	return sonar_mask == (1 << SONAR_COUNT) - 1


func on_sonar(index: int, at: Vector2) -> void:
	if not GameState.playing or index < 0 or index >= SONAR_COUNT:
		return
	var bit := 1 << index
	if sonar_mask & bit:
		return
	sonar_mask |= bit
	GameState.add_score(SONAR_POINTS, at)
	if is_kraken_active():
		GameState.say("¡KRAKEN ACTIVO!")
	changed.emit()


func on_kraken(at: Vector2) -> void:
	if not GameState.playing:
		return
	if not is_kraken_active():
		GameState.add_score(KRAKEN_POINTS, at)
		return
	GameState.add_score(JACKPOT_POINTS, at)
	sonar_mask = 0
	depth += DEPTH_STEP
	GameState.say("¡JACKPOT!  %d m" % depth)
	changed.emit()
	jackpot.emit()
