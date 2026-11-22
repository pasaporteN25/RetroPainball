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


static var _outline := PackedVector2Array()
static var _ribs := PackedVector2Array()


static func _build_shapes() -> void:
	if not _outline.is_empty():
		return
	# Mitad derecha del murciélago (orejas, ala con festones); se espeja para la izquierda.
	var half := [Vector2(0, -3), Vector2(1.6, -6.5), Vector2(3.2, -3.2), Vector2(8, -6), Vector2(14, -9),
		Vector2(20, -5), Vector2(22, -1), Vector2(17.5, -1.5), Vector2(15.5, 3), Vector2(11.5, 0.5),
		Vector2(8.5, 5), Vector2(5, 1.5), Vector2(2.5, 6), Vector2(0, 4)]
	for p in half:
		_outline.append(Vector2(p.x * 1.2, p.y * 1.25))
	for i in range(half.size() - 1, -1, -1):
		_outline.append(Vector2(-half[i].x * 1.2, half[i].y * 1.25))
	# Nervaduras del ala: del hombro a la punta y a cada muesca.
	for target in [Vector2(14, -9), Vector2(20, -5), Vector2(15.5, 3), Vector2(8.5, 5)]:
		for side in [1.0, -1.0]:
			_ribs.append(Vector2(side * 3.0 * 1.2, -2.5 * 1.25))
			_ribs.append(Vector2(side * target.x * 1.2 * 0.92, target.y * 1.25 * 0.92))


func _draw() -> void:
	_build_shapes()
	var level := maxf(_flash, LIT_LEVEL if activated else 0.0)
	var light := tint.lerp(Color.WHITE, _flash * 0.7)
	if level > 0.0:
		draw_circle(Vector2(0, -1), 33.0, Color(light, 0.08 + 0.1 * level), true, -1.0, true)
	_draw_silhouette(level, light)


func _draw_silhouette(level: float, light: Color) -> void:
	# Apagado: hueso grisáceo, ojos oscuros. Encendido: blanco pleno con ojos y resplandor carmesí.
	var closed := _outline + PackedVector2Array([_outline[0]])
	draw_set_transform(Vector2(3, 4))
	draw_colored_polygon(_outline, Color(0, 0, 0, 0.45))
	draw_set_transform(Vector2.ZERO)
	draw_polyline(closed, NIGHT, 5.0, true)
	var off := Color("#8d889c")
	var on := Color("#ffffff")
	var body := off.lerp(on, clampf(level, 0.0, 1.0))
	draw_colored_polygon(_outline, body)
	draw_multiline(_ribs, Color(NIGHT, 0.32), 1.2, true)
	draw_polyline(closed, GOLD.lerp(light, level * 0.8), 1.5, true)
	# Cuerpo y cabeza: pequeño núcleo más oscuro para dar volumen.
	draw_colored_polygon(PackedVector2Array([Vector2(-3.2, -3.5), Vector2(0, -2), Vector2(3.2, -3.5),
		Vector2(2.2, 6), Vector2(0, 8), Vector2(-2.2, 6)]), body.darkened(0.22))
	InsertLamp.draw(self, Vector2(-2.6, -3.4), 1.7, tint, level)
	InsertLamp.draw(self, Vector2(2.6, -3.4), 1.7, tint, level)
