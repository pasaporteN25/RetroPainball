extends Node
## Misión de profundidad: tres sonares activan al kraken; golpear al kraken
## activo da el jackpot y baja un escalón de profundidad.
## El progreso sobrevive a la pérdida de bolas; solo reset() lo borra.

signal changed
signal jackpot

## Valor por defecto del escalón de profundidad. Lo usa el arte (nautilus_art.gd) para las lámparas;
## las reglas leen `TableRules.depth_step` (S-03), que por defecto es el mismo.
const DEPTH_STEP := 1500

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


func sonar_count() -> int:
	return GameState.active_rules().sonar_count


func is_kraken_active() -> bool:
	return sonar_mask == (1 << sonar_count()) - 1


func on_sonar(index: int, at: Vector2) -> void:
	if not GameState.playing or index < 0 or index >= sonar_count():
		return
	var bit := 1 << index
	if sonar_mask & bit:
		return
	sonar_mask |= bit
	var rules := GameState.active_rules()
	GameState.add_score(rules.sonar_points, at)
	if is_kraken_active():
		GameState.say(rules.text("kraken_active"))
	changed.emit()


func on_kraken(at: Vector2) -> void:
	if not GameState.playing:
		return
	var rules := GameState.active_rules()
	if not is_kraken_active():
		GameState.add_score(rules.kraken_points, at)
		return
	var jackpot_stage := rules.kraken_jackpot
	GameState.add_score(jackpot_stage.award, at)
	sonar_mask = 0
	depth += rules.depth_step
	if jackpot_stage.raise_multiplier:
		GameState.raise_multiplier(false)
	if not jackpot_stage.message.is_empty():
		GameState.say(TableRules.fill(jackpot_stage.message,
			{"depth": depth, "bonus": GameState.bonus_multiplier, "award": jackpot_stage.award}))
	changed.emit()
	jackpot.emit()
