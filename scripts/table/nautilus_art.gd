@tool
extends Node2D
## Ilustración, metal grabado y luces de misión del Nautilus.

const GOLD := Color("#ffd39a")
const Ambient := preload("res://scripts/fx/nautilus_ambient.gd")
const InsertLamp := preload("res://scripts/fx/insert_lamp.gd")
const DepthMission := preload("res://scripts/table/depth_mission.gd")
const DEPTH_LAMP_COUNT := 8
const BRASS := Color("#9e6c3c")
const AQUA := Color("#7cf9df")
const INK := Color("#071720")
const ART_RECT := Rect2(16, 126, 692, 1375)
const BRIDGE := Rect2(224, 996, 224, 132)
const SAVE := Rect2(264, 1335, 144, 47)
const TITLE := "20.000 LEGUAS"
const TITLE_AT := Vector2(360, 289)
const TITLE_SIZE := 49
const SUBTITLE := "BAJO EL MAR"
const SUBTITLE_AT := TITLE_AT + Vector2(0, 31)
const SUBTITLE_SIZE := 20

@export var illustration: Texture2D
var _instruments: Node2D
var _title_font: SystemFont
var _depth := 0
var _display_depth := 0.0
var _sonar_mask := 0
var _kraken_armed := false
var _save_fraction := 0.0
var _flash := 0.0
var _jackpot := 0.0
var _clock := 0.0
var _next_redraw := 0.0


func _ready() -> void:
	_title_font = SystemFont.new()
	_title_font.font_names = PackedStringArray(["Noto Serif", "DejaVu Serif", "serif"])
	_title_font.font_weight = 700
	var ambient := Ambient.new()
	ambient.name = "Ambient"
	add_child(ambient)
	_instruments = Node2D.new()
	_instruments.name = "Instruments"
	_instruments.draw.connect(_draw_instruments)
	add_child(_instruments)
	set_process(not Engine.is_editor_hint())


func set_ball_save_fraction(fraction: float) -> void:
	_save_fraction = fraction
	_instruments.queue_redraw()


func set_mission_status(mask: int, depth: int, armed: bool) -> void:
	if depth != _depth:
		_depth = depth
		queue_redraw()
	_sonar_mask = mask
	_kraken_armed = armed
	_instruments.queue_redraw()


func pulse_score() -> void:
	_flash = 1.0


func flash_jackpot() -> void:
	_jackpot = 1.0


func _process(delta: float) -> void:
	_clock += delta
	_display_depth = move_toward(_display_depth, float(_depth), delta * 900.0)
	_flash = maxf(0.0, _flash - delta * 2.8)
	_jackpot = maxf(0.0, _jackpot - delta * 0.77)
	if _clock >= _next_redraw:
		_next_redraw = _clock + 1.0 / 30.0
		_instruments.queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 720, 2000), Color("#0b151c"))
	var shell := PackedVector2Array()
	for y in range(115, 1451, 7):
		shell.append(Vector2(0, y))
		shell.append(Vector2(720, y))
	draw_multiline(shell, Color(0.56, 0.69, 0.58, 0.094))
	_draw_illustration()
	for x in [6, 714]:
		draw_line(Vector2(x, 118), Vector2(x, 1450), BRASS.darkened(0.24), 1.5, true)
		for y in range(159, 1450, 140):
			_draw_rivet(Vector2(x, y))
	_draw_crest()
	_draw_hardware()


func _draw_illustration() -> void:
	var collision := get_node_or_null("../OuterWall/Shape") as CollisionPolygon2D
	if collision == null:
		return
	var field := PackedVector2Array()
	var uv := PackedVector2Array()
	for point in collision.polygon:
		point.y = minf(point.y, ART_RECT.end.y)
		field.append(point)
		uv.append((point - ART_RECT.position) / ART_RECT.size)
	draw_colored_polygon(field, Color("#123a43"))
	if illustration:
		var descent := clampf(_depth / 12000.0, 0.0, 1.0)
		var shade := Color("#e9eeea").lerp(Color("#a4b5ce"), descent)
		draw_polygon(field, PackedColorArray([shade]), uv, illustration)


func _draw_crest() -> void:
	var width := _title_font.get_string_size(TITLE, HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_SIZE).x
	var baseline := TITLE_AT - Vector2(width * 0.5, 0)
	draw_string_outline(_title_font, baseline + Vector2(0, 4), TITLE,
		HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_SIZE, 11, Color("#092128"))
	draw_string_outline(_title_font, baseline, TITLE,
		HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_SIZE, 4, Color("#2b271e"))
	draw_string(_title_font, baseline, TITLE, HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_SIZE, GOLD)
	var font := ThemeDB.fallback_font
	var tag_width := font.get_string_size(SUBTITLE, HORIZONTAL_ALIGNMENT_LEFT, -1, SUBTITLE_SIZE).x
	var tag_at := SUBTITLE_AT - Vector2(tag_width * 0.5, 0)
	draw_string_outline(font, tag_at, SUBTITLE, HORIZONTAL_ALIGNMENT_LEFT, -1, SUBTITLE_SIZE, 5, INK)
	draw_string(font, tag_at, SUBTITLE, HORIZONTAL_ALIGNMENT_LEFT, -1, SUBTITLE_SIZE, Color("#deece0"))
	for side in [-1.0, 1.0]:
		var v := Vector2(side, 0)
		var at := SUBTITLE_AT - Vector2(0, 7)
		draw_line(at + v * 81, at + v * 116, GOLD, 1.3, true)


func _draw_hardware() -> void:
	var rail := Rect2(663, 443, 44, 985)
	draw_rect(rail, Color("#111e24"))
	draw_rect(rail.grow(-4), Color("#203844"))
	draw_rect(rail.grow(-7), Color("#12282f"), false, 2)
	draw_line(Vector2(672, 449), Vector2(672, 1390), BRASS, 2, true)
	draw_line(Vector2(700, 449), Vector2(700, 1390), BRASS.darkened(0.4), 2, true)
	for y in range(487, 1268, 44):
		draw_polyline(PackedVector2Array([Vector2(678, y + 5), Vector2(686, y - 2), Vector2(694, y + 5)]),
			Color("#66968d") if y < 1150 else GOLD, 1.7, true)
	var pressure_path := PackedVector2Array([Vector2(563, 735), Vector2(575, 701),
		Vector2(585, 668), Vector2(592, 635), Vector2(596, 609)])
	draw_polyline(pressure_path, Color(0.027, 0.12, 0.15, 0.74), 11.0, true)
	for i in range(pressure_path.size() - 1):
		var from := pressure_path[i]
		var to := pressure_path[i + 1]
		var cross := (to - from).normalized().orthogonal() * 5.0
		draw_line(from.lerp(to, 0.24), from.lerp(to, 0.88), Color(AQUA, 0.43), 2.0, true)
		draw_line(from - cross, from + cross, Color(GOLD, 0.69), 1.5, true)

	# Escala grabada a los lados del campo abierto.
	for x in [116.0, 556.0]:
		var direction := 1 if x < 336 else -1
		for i in 11:
			var point := Vector2(x, 672 + i * 19)
			var tick := 14 if i % 5 == 0 else 7
			draw_line(point, point + Vector2(direction * tick, 0), Color(GOLD, 0.3), 1.6, true)
	_plate(BRIDGE, Color("#10232a"))
	_plate(SAVE, Color("#0b1c23"))
	var chute := Rect2(273, 1396, 126, 25)
	draw_rect(chute.grow(2), BRASS.darkened(0.55))
	draw_rect(chute, Color("#040d15"))
	draw_line(Vector2(16, 1438), Vector2(707, 1438), Color("#635138"), 2, true)


func _plate(rect: Rect2, tint: Color) -> void:
	var c := 12.0
	var hull := PackedVector2Array([
		rect.position + Vector2(c, 0), Vector2(rect.end.x - c, rect.position.y),
		Vector2(rect.end.x, rect.position.y + c), Vector2(rect.end.x, rect.end.y - c),
		rect.end - Vector2(c, 0), Vector2(rect.position.x + c, rect.end.y),
		Vector2(rect.position.x, rect.end.y - c), rect.position + Vector2(0, c),
	])
	draw_colored_polygon(hull, tint)
	hull.append(hull[0])
	draw_polyline(hull, BRASS, 2.0, true)
	draw_line(hull[0] + Vector2(2, 3), hull[1] + Vector2(-2, 3), Color(GOLD, 0.50), 1.5, true)
	for x in [rect.position.x + 11, rect.end.x - 11]:
		_draw_rivet(Vector2(x, rect.get_center().y))


func _draw_rivet(at: Vector2) -> void:
	draw_circle(at, 4.1, Color("#362c24"), true, -1, true)
	draw_circle(at - Vector2(0, 0.9), 2.6, BRASS, true, -1, true)
	draw_line(at - Vector2(1.6, 0), at + Vector2(1.6, 0), Color("#1f2425"), 1, true)


func _draw_instruments() -> void:
	var tint := GOLD if _kraken_armed else AQUA
	var nodes := Vector2(336, 959)
	for i in 3:
		var active := bool(_sonar_mask & (1 << i))
		var light := nodes + Vector2((i - 1) * 37, 0)
		_instruments.draw_circle(light, 13, INK, true, -1, true)
		_instruments.draw_circle(light, 11, BRASS, false, 1.6, true)
		InsertLamp.draw(_instruments, light, 7.0, tint, 1.0 if active else 0.0)
	_center_label("PROFUNDIDAD", Vector2(336, 1023), 15, GOLD)
	var reading := "%d m" % _depth
	_center_label(reading, Vector2(336, 1070), 37, tint.lerp(Color.WHITE, 0.28 + _flash * 0.36))
	for i in DEPTH_LAMP_COUNT:
		var active := _depth >= (i + 1) * DepthMission.DEPTH_STEP
		InsertLamp.draw(_instruments, Vector2(273 + i * 18, 1081), 4.0, AQUA, 1.0 if active else 0.0)
	var depth_fraction := clampf(_display_depth / (DEPTH_LAMP_COUNT * DepthMission.DEPTH_STEP), 0.0, 1.0)
	_instruments.draw_rect(Rect2(273, 1089, 130, 3), Color("#253a42"))
	_instruments.draw_rect(Rect2(273, 1089, 130 * depth_fraction, 3), AQUA.lerp(Color.WHITE, _jackpot * 0.7))
	var hint := "GOLPEÁ AL KRAKEN" if _kraken_armed else "ACTIVÁ LOS 3 SONARES"
	_center_label(hint, Vector2(336, 1105), 14, tint.lerp(Color.WHITE, 0.18))
	_center_label("SALVABOLAS", Vector2(336, 1361), 15, AQUA if _save_fraction > 0 else Color("#88a39f"))
	_instruments.draw_rect(Rect2(282, 1367, 108, 3), Color("#253a42"))
	if _save_fraction > 0:
		_instruments.draw_rect(Rect2(282, 1367, 108 * _save_fraction, 3), AQUA)
	if _jackpot > 0.0:
		var center := Vector2(336, 795)
		var radius := lerpf(315.0, 82.0, _jackpot)
		_instruments.draw_arc(center, radius, 0, TAU, 48, Color(GOLD, _jackpot * 0.3), 5.0, true)
		_instruments.draw_arc(center, radius * 0.88, 0, TAU, 48, Color(AQUA, _jackpot * 0.36), 2.0, true)


func _center_label(text: String, at: Vector2, font_size: int, tint: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_instruments.draw_string(font, at - Vector2(width * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, tint)
