@tool
extends Node2D
## Arte original de Drácula: paisaje impreso (capa estática) y efectos ambientales suaves (capa dinámica).
## La capa estática se redibuja solo cuando cambia algo del estado; la dinámica, a 20 Hz como máximo.

const Ambient := preload("res://scripts/table/dracula_ambient.gd")
const NIGHT := Color("#0b0a14")
const BLUE := Color("#1b2140")
const RED := Color("#9e1b32")
const MOON := Color("#c9d3e6")
const GOLD := Color("#c9a35a")
const BONE := Color("#e9e1cf")
const FOG := Color("#3a4468")
const STONE := Color("#0d0c1a")
const ARCH_CENTER := Vector2(362, 472)
const ARCH_RADIUS := 346.0
const TITLE := "DRÁCULA"
const TITLE_AT := Vector2(336, 216)
const TITLE_SIZE := 34
const SUBTITLE := "NOCHE EN TRANSILVANIA"
const SUBTITLE_AT := TITLE_AT + Vector2(0, 20)
const SUBTITLE_SIZE := 12
const FIELD_BOTTOM := 1440.0
const MOON_AT := Vector2(480, 296)
const BAND_COUNT := 44
const BAND_TOP := 126.0
const BAND_STEP := 30.0
## Ventanas del castillo (x, y, ancho, alto); la 0 es la del LOCK.
const WINDOWS := [Rect2(251, 318, 8, 14), Rect2(142, 312, 6, 10), Rect2(222, 322, 6, 10),
	Rect2(282, 322, 6, 10), Rect2(324, 306, 7, 11), Rect2(324, 330, 7, 11), Rect2(389, 326, 5, 9),
	Rect2(175, 336, 5, 8)]

var BAT := PackedVector2Array()
var _font: SystemFont
var _ambient: Node2D
var _field := PackedVector2Array()
var _bands: Array[PackedVector2Array] = []
var _band_colors := PackedColorArray()
var _top_field := PackedVector2Array()
var _top_colors := PackedColorArray()
var _lane := PackedVector2Array()
var _apron := PackedVector2Array()
var _stars := PackedVector2Array()
var _save_fraction := 0.0
var _flash := 0.0
var _jackpot := 0.0
var _time := 0.0
var _redraw_elapsed := 0.0
var _midnight := false
var _lock_lit := false
var _sky_mix := 0.0


func _ready() -> void:
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Noto Serif", "DejaVu Serif", "serif"])
	_font.font_weight = 700
	_build_bat()
	_build_field()
	_ambient = Ambient.new()
	_ambient.name = "Ambient"
	_ambient.art = self
	add_child(_ambient)
	var rules := get_node_or_null("../DraculaRules")
	if rules:
		if rules.has_signal("midnight_started"):
			rules.connect("midnight_started", _on_midnight_started)
		if rules.has_signal("midnight_ended"):
			rules.connect("midnight_ended", _on_midnight_ended)
		if rules.has_signal("lock_lit_changed"):
			rules.connect("lock_lit_changed", _on_lock_lit_changed)
		# Leer el estado inicial también permite incorporar el arte con reglas ya activas.
		for property in rules.get_property_list():
			if property.name == "midnight":
				_midnight = bool(rules.get("midnight"))
			elif property.name == "locks_lit":
				_lock_lit = bool(rules.get("locks_lit"))
		_sky_mix = 1.0 if _midnight else 0.0
	set_process(not Engine.is_editor_hint())


func pulse_score() -> void:
	_flash = 1.0
	_ambient.queue_redraw()


func flash_jackpot() -> void:
	_jackpot = 1.0
	_ambient.queue_redraw()


func set_ball_save_fraction(fraction: float) -> void:
	_save_fraction = clampf(fraction, 0.0, 1.0)
	_ambient.queue_redraw()


func _on_midnight_started() -> void:
	_midnight = true


func _on_midnight_ended() -> void:
	_midnight = false


func _on_lock_lit_changed(lit: bool) -> void:
	_lock_lit = lit
	_ambient.queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	_flash = move_toward(_flash, 0.0, delta * 2.0)
	_jackpot = move_toward(_jackpot, 0.0, delta * 0.6)
	_sky_mix = move_toward(_sky_mix, 1.0 if _midnight else 0.0, delta * 0.3)
	_redraw_elapsed += delta
	if _redraw_elapsed >= 1.0 / 20.0:
		_redraw_elapsed = 0.0
		_ambient.queue_redraw()


# ---------------------------------------------------------------- geometría cacheada

func _build_bat() -> void:
	# Silueta original: orejas, alas con festones. Se arma una vez y se reutiliza para todos.
	var half := [Vector2(0, -3), Vector2(1.6, -6.5), Vector2(3.2, -3.2), Vector2(8, -6), Vector2(14, -9),
		Vector2(20, -5), Vector2(22, -1), Vector2(17.5, -1.5), Vector2(15.5, 3), Vector2(11.5, 0.5),
		Vector2(8.5, 5), Vector2(5, 1.5), Vector2(2.5, 6), Vector2(0, 4)]
	BAT = PackedVector2Array()
	for p in half:
		BAT.append(p)
	for i in range(half.size() - 1, -1, -1):
		BAT.append(Vector2(-half[i].x, half[i].y))


func _build_field() -> void:
	var source := PackedVector2Array()
	var shape := get_node_or_null("../OuterWall/Shape") as CollisionPolygon2D
	if shape and shape.polygon.size() > 3:
		source = shape.polygon
	else:
		for i in 25:
			source.append(ARCH_CENTER + Vector2.from_angle(PI + PI * i / 24.0) * ARCH_RADIUS)
		source.append(Vector2(708, 1800))
		source.append(Vector2(16, 1800))
	_field = PackedVector2Array()
	for point in source:
		_field.append(Vector2(point.x, minf(point.y, FIELD_BOTTOM)))
	_bands.clear()
	_band_colors = PackedColorArray()
	for i in BAND_COUNT:
		var rect := PackedVector2Array([Vector2(0, BAND_TOP + i * BAND_STEP), Vector2(720, BAND_TOP + i * BAND_STEP),
			Vector2(720, BAND_TOP + (i + 1) * BAND_STEP + 1.0), Vector2(0, BAND_TOP + (i + 1) * BAND_STEP + 1.0)])
		var clipped := Geometry2D.intersect_polygons(_field, rect)
		if not clipped.is_empty():
			_bands.append(clipped[0])
			_band_colors.append(_sky_color(BAND_TOP + (i + 0.5) * BAND_STEP))
	_top_field = _clip(Rect2(0, 100, 720, 720))
	_top_colors.resize(_top_field.size())
	_lane = _clip(Rect2(664, 430, 60, FIELD_BOTTOM - 430))
	_apron = _clip(Rect2(0, 1320, 664, 130))
	_stars = PackedVector2Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1897
	var title_area := Rect2(TITLE_AT - Vector2(116, 39), Vector2(232, 65))
	while _stars.size() < 46:
		var p := Vector2(rng.randf_range(40, 690), rng.randf_range(138, 330))
		if Geometry2D.is_point_in_polygon(p, _field) and p.distance_to(MOON_AT) > 52.0 \
				and not title_area.has_point(p):
			_stars.append(p)


func _clip(rect: Rect2) -> PackedVector2Array:
	var points := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end,
		Vector2(rect.position.x, rect.end.y)])
	var clipped := Geometry2D.intersect_polygons(_field, points)
	return clipped[0] if not clipped.is_empty() else points


func _sky_color(y: float) -> Color:
	# Cielo de tormenta: cenit casi negro, resplandor frío en el horizonte, fondo sobrio bajo las piezas.
	var top := Color("#0e1230")
	var horizon := Color("#2a3664")
	var low := Color("#161b3a")
	var bottom := NIGHT
	if y < 360.0:
		return top.lerp(horizon, smoothstep(126.0, 360.0, y))
	if y < 620.0:
		return horizon.lerp(low, smoothstep(360.0, 620.0, y))
	return low.lerp(bottom, smoothstep(620.0, 1150.0, y))


func _arch_half_width(y: float) -> float:
	if y >= ARCH_CENTER.y:
		return ARCH_RADIUS
	var dy := ARCH_CENTER.y - y
	return sqrt(maxf(0.0, ARCH_RADIUS * ARCH_RADIUS - dy * dy))


# ---------------------------------------------------------------- capa estática

func _draw() -> void:
	if _bands.is_empty():
		return
	# Gabinete fuera del contorno del campo.
	draw_rect(Rect2(0, 100, 720, 1400), Color("#06050b"))
	draw_rect(Rect2(0, 115, 11, 1330), Color("#171426"))
	draw_rect(Rect2(709, 115, 11, 1330), Color("#171426"))
	draw_line(Vector2(8, 116), Vector2(8, 1450), Color(GOLD, 0.35), 1.0)
	draw_line(Vector2(713, 116), Vector2(713, 1450), Color(GOLD, 0.35), 1.0)
	for x in [5, 715]:
		for y in [142, 452, 780, 1120, 1428]:
			draw_circle(Vector2(x, y), 3.0, Color(GOLD, 0.45), true, -1.0, true)
	# Campo: degradé por bandas recortadas al contorno real de la mesa.
	for i in _bands.size():
		draw_colored_polygon(_bands[i], _band_colors[i])
	_draw_sky_details()
	_draw_castle()
	_draw_floor_marks()
	# Viñeta: oscurece los bordes del campo para dar profundidad.
	var closed := _field + PackedVector2Array([_field[0]])
	draw_polyline(closed, Color(0, 0, 0, 0.12), 70.0, true)
	draw_polyline(closed, Color(0, 0, 0, 0.14), 36.0, true)
	draw_polyline(closed, Color(0, 0, 0, 0.18), 14.0, true)
	_draw_title()
	_draw_lane()
	_draw_apron()


func _draw_sky_details() -> void:
	for i in _stars.size():
		var big := i % 5 == 0
		draw_circle(_stars[i], 1.3 if big else 0.8, Color(MOON, 0.55 if big else 0.32))
	# Halo lunar en capas y luna llena con mares y cráteres.
	for i in 6:
		draw_circle(MOON_AT, 98.0 - i * 10.0, Color(MOON, 0.022 + i * 0.004), true, -1, true)
	draw_circle(MOON_AT, 39, Color("#dfe6f2"), true, -1, true)
	draw_circle(MOON_AT + Vector2(-6, -4), 36, Color(MOON, 0.9), true, -1, true)
	draw_circle(MOON_AT + Vector2(-12, -10), 8, Color("#9aa7c2", 0.5), true, -1, true)
	draw_circle(MOON_AT + Vector2(11, 8), 11, Color("#9aa7c2", 0.45), true, -1, true)
	draw_circle(MOON_AT + Vector2(-8, 14), 5, Color("#9aa7c2", 0.45), true, -1, true)
	draw_circle(MOON_AT + Vector2(14, -14), 4, Color("#9aa7c2", 0.4), true, -1, true)
	draw_arc(MOON_AT, 39, 0.0, TAU, 40, Color.WHITE * Color(1, 1, 1, 0.35), 1.2, true)


func _tower(body: Rect2, roof_peak: float, overhang := 5.0) -> void:
	draw_rect(body, STONE)
	var roof := PackedVector2Array([Vector2(body.position.x - overhang, body.position.y + 1),
		Vector2(body.get_center().x, roof_peak), Vector2(body.end.x + overhang, body.position.y + 1)])
	draw_colored_polygon(roof, Color("#0a0914"))
	draw_polyline(roof, Color(MOON, 0.28), 1.3, true)
	draw_line(Vector2(body.end.x, body.position.y), Vector2(body.end.x, body.end.y), Color(MOON, 0.16), 1.2, true)


func _battlements(x0: float, x1: float, y: float) -> void:
	var x := x0
	while x + 6.0 <= x1:
		draw_rect(Rect2(x, y - 6.0, 6.0, 6.0), STONE)
		draw_line(Vector2(x + 6.0, y - 6.0), Vector2(x + 6.0, y), Color(MOON, 0.12), 1.0)
		x += 12.0


func _draw_castle() -> void:
	# Risco: roca bajo el castillo, iluminada por el lado de la luna.
	var crag := PackedVector2Array([Vector2(30, 420), Vector2(58, 396), Vector2(84, 392), Vector2(100, 376),
		Vector2(126, 360), Vector2(150, 356), Vector2(384, 356), Vector2(404, 370), Vector2(430, 372),
		Vector2(452, 392), Vector2(480, 404), Vector2(500, 430), Vector2(30, 440)])
	var crag_colors := PackedColorArray()
	for point in crag:
		crag_colors.append(Color("#0a0914", 1.0 - smoothstep(372.0, 436.0, point.y)))
	draw_polygon(crag, crag_colors)
	draw_polyline(crag.slice(0, 11), Color(MOON, 0.2), 1.4, true)
	# Muralla y cuerpos (de atrás hacia adelante).
	draw_rect(Rect2(160, 322, 45, 36), STONE)
	_battlements(160, 205, 322)
	draw_rect(Rect2(344, 330, 38, 28), STONE)
	_battlements(344, 382, 330)
	draw_rect(Rect2(205, 300, 100, 58), STONE)
	_battlements(205, 305, 300)
	draw_polyline(PackedVector2Array([Vector2(205, 300), Vector2(305, 300)]), Color(MOON, 0.2), 1.2, true)
	# Torres con techos cónicos; la del reloj es la más alta.
	_tower(Rect2(132, 296, 28, 62), 262.0)
	_tower(Rect2(238, 268, 34, 34), 240.0, 6.0)
	_tower(Rect2(312, 290, 32, 68), 258.0)
	_tower(Rect2(380, 306, 24, 52), 282.0, 4.0)
	# Puerta ojival y arco del puente.
	var gate := PackedVector2Array([Vector2(240, 358), Vector2(240, 342), Vector2(247, 331), Vector2(255, 327),
		Vector2(263, 331), Vector2(270, 342), Vector2(270, 358)])
	draw_colored_polygon(gate, Color("#06050b"))
	draw_polyline(gate, Color(GOLD, 0.2), 1.0, true)
	# Ventanas apagadas (las encendidas se dibujan en la capa dinámica).
	for w in WINDOWS:
		draw_rect(w, Color("#171526"))
	# Pináculos con veleta.
	for x in [146.0, 255.0, 328.0, 392.0]:
		var top := 262.0 if x == 146.0 else (240.0 if x == 255.0 else (258.0 if x == 328.0 else 282.0))
		draw_line(Vector2(x, top), Vector2(x, top - 9), Color(MOON, 0.3), 1.2, true)
	draw_colored_polygon(PackedVector2Array([Vector2(255, 231), Vector2(266, 234), Vector2(255, 237)]), Color(RED, 0.8))


func _draw_floor_marks() -> void:
	# Zonas tenues bajo las piezas: nunca compiten con las lámparas ni con la bola.
	for p in [Vector2(210, 610), Vector2(462, 610), Vector2(336, 530)]:
		draw_circle(p, 62, Color(RED, 0.05), true, -1, true)
		draw_arc(p, 56, 0, TAU, 36, Color(GOLD, 0.07), 1.5, true)
	# Rosetón gótico detrás del retrato.
	var portrait := Vector2(336, 830)
	draw_arc(portrait, 108, 0, TAU, 56, Color(GOLD, 0.09), 1.5, true)
	draw_arc(portrait, 92, 0, TAU, 56, Color(MOON, 0.05), 1.0, true)
	for i in 12:
		var a := i * TAU / 12.0
		var dir := Vector2.from_angle(a)
		draw_line(portrait + dir * 66, portrait + dir * 106, Color(GOLD, 0.07), 1.2, true)
		draw_arc(portrait + dir * 99, 9, 0, TAU, 12, Color(GOLD, 0.07), 1.0, true)
	# Arco de cripta junto al ataúd.
	var crypt := PackedVector2Array([Vector2(108, 880), Vector2(108, 800), Vector2(120, 756), Vector2(150, 730),
		Vector2(180, 756), Vector2(192, 800), Vector2(192, 880)])
	draw_polyline(crypt, Color(GOLD, 0.08), 1.5, true)
	# Baldosas muy suaves hacia el fondo, sin invadir la franja del multiplicador.
	for i in 4:
		draw_line(Vector2(65, 930 + i * 43), Vector2(607, 930 + i * 43), Color(MOON, 0.03), 1, true)


func _draw_title() -> void:
	_draw_centered(TITLE, TITLE_AT, TITLE_SIZE, BONE)
	_draw_centered(SUBTITLE, SUBTITLE_AT, SUBTITLE_SIZE, Color(GOLD, 0.92))
	# Filetes dorados con rombos a los lados del subtítulo.
	for side in [-1.0, 1.0]:
		var base := SUBTITLE_AT + Vector2(side * 104, -4.5)
		draw_line(base, base + Vector2(side * 30, 0), Color(GOLD, 0.5), 1.0, true)
		draw_colored_polygon(PackedVector2Array([base + Vector2(0, -3), base + Vector2(side * 4, 0), base + Vector2(0, 3),
			base + Vector2(-side * 4, 0)]), Color(RED, 0.9))


func _draw_lane() -> void:
	# Carril de lanzamiento propio: madera oscura con rieles dorados y flechas.
	draw_colored_polygon(_lane, Color("#100e1b"))
	draw_rect(Rect2(664, 443, 44, 990), Color("#171428", 0.0))
	for i in 10:
		var t := float(i) / 9.0
		draw_rect(Rect2(668, 900 + i * 53, 36, 54), Color(RED, 0.012 + 0.045 * t))
	draw_line(Vector2(672, 449), Vector2(672, 1432), Color(GOLD, 0.6), 2, true)
	draw_line(Vector2(700, 449), Vector2(700, 1432), Color(MOON, 0.25), 2, true)
	draw_line(Vector2(686, 449), Vector2(686, 1432), Color(GOLD, 0.05), 10, true)
	for y in range(487, 1268, 44):
		draw_line(Vector2(678, y + 5), Vector2(686, y - 2), Color(GOLD, 0.45), 1.5, true)
		draw_line(Vector2(686, y - 2), Vector2(694, y + 5), Color(GOLD, 0.45), 1.5, true)


func _draw_apron() -> void:
	draw_colored_polygon(_apron, Color("#15121d"))
	draw_line(Vector2(16, 1322), Vector2(656, 1322), Color(GOLD, 0.16), 1.0)
	draw_line(Vector2(16, FIELD_BOTTOM - 1.0), Vector2(707, FIELD_BOTTOM - 1.0), Color(GOLD, 0.5), 2)
	for x in [60.0, 612.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(x, 1350), Vector2(x + 7, 1357), Vector2(x, 1364),
			Vector2(x - 7, 1357)]), Color(RED, 0.8))


func _draw_centered(label: String, at: Vector2, size: int, color: Color) -> void:
	var width := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var start := at - Vector2(width * 0.5, 0)
	draw_string_outline(_font, start, label, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 5, NIGHT)
	draw_string(_font, start, label, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
