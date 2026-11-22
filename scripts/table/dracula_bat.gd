@tool
extends StaticBody2D
## Murciélago del banco: blanco fijo que queda "activado" al golpearlo hasta que el banco se reinicia.

const InsertLamp := preload("res://scripts/fx/insert_lamp.gd")

## Se emite cuando la bola golpea el blanco (DraculaRules lo escucha).
signal hit

@export var points := 150
@export var tint := Color("#c0314d")

## Brillo de los insertos mientras el murciélago está activado.
const LIT_LEVEL := 0.85
const NIGHT := Color("#0b0a14")
const MIDNIGHT_BLUE := Color("#1b2140")
const BONE := Color("#e9e1cf")
const GOLD := Color("#c9a35a")
## Mitad derecha de la silueta (la izquierda se espeja).
const WING := [Vector2(0, -6), Vector2(4, -12), Vector2(7, -6), Vector2(15, -10),
	Vector2(27, -4), Vector2(23, 0), Vector2(19, 5), Vector2(14, 1), Vector2(9, 7),
	Vector2(5, 2), Vector2(0, 8)]

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
	strike.call_deferred()


## Registra el golpe: puntos, brillo y aviso al banco. Público para poder probarlo sin física.
func strike() -> void:
	if not GameState.playing:
		return
	GameState.add_score(points, global_position)
	activated = true
	_flash = 1.0
	set_process(true)
	queue_redraw()
	Input.vibrate_handheld(8)
	hit.emit()


## Apaga o enciende el murciélago (el banco lo apaga al completarse).
func set_activated(value: bool) -> void:
	activated = value
	queue_redraw()


func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta * 2.85)
	queue_redraw()
	if _flash == 0.0:
		set_process(false)


func _draw() -> void:
	var level := maxf(_flash, LIT_LEVEL if activated else 0.0)
	var light := tint.lerp(Color.WHITE, _flash * 0.7)
	_draw_silhouette(level, light)
	InsertLamp.draw(self, Vector2(-5, -1), 2.5, tint, level)
	InsertLamp.draw(self, Vector2(5, -1), 2.5, tint, level)
	if _flash > 0.0:
		draw_circle(Vector2.ZERO, 30.0, Color(light, _flash * 0.18), true, -1.0, true)


func _draw_silhouette(level: float, light: Color) -> void:
	var half := PackedVector2Array(WING)
	var mirrored := PackedVector2Array()
	for i in range(half.size() - 1, -1, -1):
		mirrored.append(Vector2(-half[i].x, half[i].y))
	var outline := mirrored + half
	var body := MIDNIGHT_BLUE.lerp(light.darkened(0.45), level)
	draw_colored_polygon(outline, body)
	draw_polyline(outline + PackedVector2Array([outline[0]]), GOLD.lerp(light, level), 1.6, true)
