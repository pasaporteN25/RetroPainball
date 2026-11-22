@tool
extends StaticBody2D
## Blanco fijo de contacto con frente luminoso.

const InsertLamp := preload("res://scripts/fx/insert_lamp.gd")

## Se emite cuando la bola golpea el blanco (el banco lo escucha).
signal hit

@export var points := 225
@export var tint := Color("#ffb874")

## Brillo de los insertos mientras el blanco está activado.
const LIT_LEVEL := 0.75

var activated := false
var _flash := 0.0


func _ready() -> void:
	set_process(false)


func on_ball_contact(_ball: RigidBody2D, state: PhysicsDirectBodyState2D, _point: Vector2) -> void:
	if not GameState.playing:
		return
	var face := Vector2.DOWN.rotated(global_rotation)
	if (state.transform.origin - global_position).dot(face) < 4.0:
		return
	GameState.add_score.call_deferred(points, global_position)
	activated = true
	_flash = 1.0
	set_process(true)
	queue_redraw()
	Settings.vibrate(8)
	hit.emit()


## Apaga o enciende el blanco (el banco lo apaga al completarse).
func set_activated(value: bool) -> void:
	activated = value
	queue_redraw()


func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta * 2.85)
	queue_redraw()
	if _flash == 0.0:
		set_process(false)


func _draw() -> void:
	var light := tint.lerp(Color.WHITE, _flash * 0.8)
	var plate := Rect2(-26, -9, 52, 18)
	draw_rect(Rect2(-28, -10, 56, 24), Color("#09161c"))
	draw_rect(plate, Color("#26323f"))
	draw_rect(plate, Color("#78909b"), false, 1.4, true)
	draw_rect(Rect2(-21, -4, 42, 10), light.darkened(0.35 - 0.29 * _flash))
	draw_line(Vector2(-22, 4), Vector2(22, 4), light, 2, true)
	for x in [-17, -9, 0, 9, 17]:
		InsertLamp.draw(self, Vector2(x, -1), 2.5, tint, maxf(_flash, LIT_LEVEL if activated else 0.0))
	if _flash > 0.0:
		draw_line(Vector2(-21, 7), Vector2(21, 7), Color(light, _flash * 0.35), 12, true)
	var font := ThemeDB.fallback_font
	draw_set_transform(Vector2.ZERO, -rotation)
	var width := font.get_string_size("IRQ", HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	var label := Vector2(-width / 2.0, 34)
	draw_string_outline(font, label, "IRQ", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, 5, Color("#09161f"))
	draw_string(font, label, "IRQ", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, light)
