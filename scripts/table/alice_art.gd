extends Node2D
## Arte de la mesa Alicia. STUB: el agente de arte lo reemplaza (ver docs/mesas/ALICIA.md).
## Mantener la API pública: pulse_score(), set_ball_save_fraction(), flash_jackpot().

var _save_fraction := 0.0


func pulse_score() -> void:
	pass


func set_ball_save_fraction(fraction: float) -> void:
	_save_fraction = fraction
	queue_redraw()


func flash_jackpot() -> void:
	pass


func _draw() -> void:
	draw_rect(Rect2(16, 126, 692, 1318), Color("#12201f"))
