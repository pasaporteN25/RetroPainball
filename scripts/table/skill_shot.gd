extends Node2D
## G-09: skill shot. Si la bola sale del lanzador con la potencia dentro de la ventana marcada
## en el resorte (skill_min..skill_max del Plunger) y entra al carril de la izquierda del arco
## antes de SKILL_TIME segundos, hay premio extra. Con poca potencia la bola no llega al carril
## y con carga completa se pasa de largo, así que hay que apuntar a la ventana.
## El carril avisa solo: titila mientras hay una bola esperando y queda dorado al armarse.

## Se emite al cobrar el premio.
signal scored(award: int)

const Ball := preload("res://scripts/table/ball.gd")
const GOLD := Color("#ffd35c")

@export var plunger_path := NodePath("../Plunger")
## Premio del skill shot; -1 = TableRules.skill_shot_award. Leer `award` da el valor efectivo.
@export var award_override := -1
var award: int:
	get:
		return award_override if award_override >= 0 else GameState.active_rules().skill_shot_award
## Rectángulo del carril (coordenadas de la mesa), pegado al arco izquierdo.
@export var lane_rect := Rect2(12.0, 290.0, 100.0, 240.0)

var armed := false
var _time_left := 0.0
var _flash := 0.0
var _clock := 0.0
var _sensor: Area2D
var _plunger: Node


func _ready() -> void:
	_sensor = Area2D.new()
	_sensor.collision_layer = 0
	_sensor.collision_mask = 2
	_sensor.monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = lane_rect.size
	shape.shape = rect
	shape.position = lane_rect.get_center()
	_sensor.add_child(shape)
	add_child(_sensor)
	_sensor.body_entered.connect(_on_body_entered)
	_plunger = get_node_or_null(plunger_path)
	if _plunger != null:
		_plunger.launched.connect(on_launched)
	GameState.game_started.connect(disarm)
	GameState.balls_changed.connect(func(_balls: int) -> void: disarm())


## Lo llama el lanzador (señal `launched`) con la potencia de 0 a 1.
func on_launched(power: float) -> void:
	var in_window := true
	if _plunger != null and _plunger.has_method("in_skill_window"):
		in_window = _plunger.in_skill_window(power)
	if not GameState.playing or not in_window:
		disarm()
		return
	armed = true
	_time_left = GameState.active_rules().skill_shot_seconds
	GameState.say(GameState.active_rules().text("skill_shot_armed"))
	queue_redraw()


func disarm() -> void:
	armed = false
	_time_left = 0.0
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if not armed or not body is Ball:
		return
	armed = false
	_flash = 1.0
	GameState.add_score.call_deferred(award, to_global(lane_rect.get_center()))
	GameState.say(GameState.active_rules().text("skill_shot_scored", {"award": award}))
	scored.emit(award)


func _process(delta: float) -> void:
	_clock += delta
	if armed:
		_time_left -= delta
		if _time_left <= 0.0:
			disarm()
	_flash = maxf(0.0, _flash - delta * 1.5)
	queue_redraw()


func _draw() -> void:
	var waiting := GameState.ball_in_lane and GameState.playing
	var pulse := 0.5 + 0.5 * sin(_clock * 7.0)
	var strength := 0.28
	if armed:
		strength = 0.9
	elif waiting:
		strength = 0.35 + 0.45 * pulse
	strength = maxf(strength, _flash)
	var c := lane_rect.get_center()
	var tint := Color(GOLD, strength)
	draw_rect(Rect2(c.x - 14.0, lane_rect.position.y + 20.0, 28.0, lane_rect.size.y - 40.0), Color(GOLD, strength * 0.12))
	# Flechas hacia arriba a lo largo del carril.
	for i in 5:
		var y := lane_rect.end.y - 40.0 - i * 40.0
		var lit := armed or (waiting and int(_clock * 6.0) % 5 == i)
		var a := strength if lit or armed else strength * 0.6
		draw_polyline(PackedVector2Array([Vector2(c.x - 8.0, y + 6.0), Vector2(c.x, y - 4.0), Vector2(c.x + 8.0, y + 6.0)]),
			Color(GOLD, a), 2.0, true)
	var font := ThemeDB.fallback_font
	var label := "SKILL SHOT"
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_set_transform(Vector2(c.x + 24.0, c.y), -PI * 0.5)
	draw_string(font, Vector2(-width * 0.5, 4.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, tint)
