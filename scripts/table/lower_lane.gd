@tool
extends Area2D
## Insertos en los carriles inferiores. El retorno suma puntos al entrar de bajada.

const Ball := preload("res://scripts/table/ball.gd")
const RETURN_POINTS := 50
const RETURN_TINT := Color("#82ead0")
const DRAIN_TINT := Color("#e18c72")

@export var is_outlane := false
var _flash := 0.0


func _ready() -> void:
	if not Engine.is_editor_hint():
		body_entered.connect(_on_crossed)
	set_process(false)


func _on_crossed(body: Node2D) -> void:
	var ball := body as Ball
	if not ball or ball.linear_velocity.y < 50.0:
		return
	_flash = 1.0
	set_process(true)
	queue_redraw()
	if not is_outlane:
		GameState.add_score.call_deferred(RETURN_POINTS, global_position)


func _process(delta: float) -> void:
	_flash = move_toward(_flash, 0.0, delta * 2.5)
	queue_redraw()
	if _flash == 0.0:
		set_process(false)


func _draw() -> void:
	var tint := DRAIN_TINT if is_outlane else RETURN_TINT
	var bed := Color("#0d141c").lerp(tint, _flash * 0.15)
	draw_rect(Rect2(-18, -48, 36, 99), bed)
	draw_line(Vector2(-17, -45), Vector2(-17, 46), Color(tint, 0.34 + _flash * 0.54), 1.2, true)
	draw_line(Vector2(17, -45), Vector2(17, 46), Color(tint, 0.34 + _flash * 0.54), 1.2, true)
	for y in [-42.0, 37.0, 44.0]:
		draw_polyline(PackedVector2Array([Vector2(-6, y), Vector2(0, y + 4), Vector2(6, y)]),
			Color(tint, 0.72 + _flash * 0.28), 1.5, true)
	var label := "DRENAJE" if is_outlane else "RETORNO"
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	draw_set_transform(Vector2(0, -2), PI * 0.5)
	draw_string(font, Vector2(-width * 0.5, 4), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, tint.lerp(Color.WHITE, _flash * 0.45))
