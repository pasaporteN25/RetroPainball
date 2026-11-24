@tool
extends Node2D
## Arte original de la mesa Alicia (A-08 / S-09): jardín nocturno con estética de grabado (trazo fino, rayado,
## brillo suave) en la línea de Tenniel (dominio público), dibujado en código. Nada de Disney ni de otras
## adaptaciones. Dos capas: la estática (esta, se redibuja solo si cambia el contorno) y la dinámica
## (`Ambient`, marco de tamaño, luciérnagas, salvabolas y destellos; a 20 Hz como máximo y sin parpadeos).
## Contrato con la lógica: docs/mesas/ALICIA.md. Si no existe `../AliceRules` el arte funciona igual.

const INK := Color("#14110f")
const GARDEN := Color("#12201f")
const PAPER := Color("#ece2c8")
const SEPIA := Color("#6b5436")
const QUEEN := Color("#b3262e")
const TEA := Color("#2f7f86")
const GOLD := Color("#c9a24a")
const LILAC := Color("#7a5fa8")
const ARCH_CENTER := Vector2(362, 472)
const ARCH_RADIUS := 346.0
# El cartel va entre las raíces de la Madriguera y el banco de naipes.
const TITLE := "ALICIA"
const TITLE_AT := Vector2(336, 329)
const TITLE_SIZE := 37
const SUBTITLE := "EN EL PAÍS DE LAS MARAVILLAS"
const SUBTITLE_AT := TITLE_AT + Vector2(0, 22)
const SUBTITLE_SIZE := 14
const SIZE_LABEL_AT := SUBTITLE_AT + Vector2(0, 17)
const SIZE_LABEL_SIZE := 11
const FIELD_BOTTOM := 1440.0
const BAND_TOP := 126.0
const BAND_STEP := 40.0
const BAND_COUNT := 33
const REDRAW_HZ := 20.0
const SIZE_NORMAL := 0
const SIZE_SMALL := 1
const SIZE_BIG := 2

var _font: SystemFont
var _ambient: Node2D
var _field := PackedVector2Array()
var _bands: Array[PackedVector2Array] = []
var _band_colors := PackedColorArray()
var _sky_lines := PackedVector2Array()
var _cross_lines := PackedVector2Array()
var _stars := PackedVector2Array()
var _hedge := PackedVector2Array()
var _lane := PackedVector2Array()
var _apron := PackedVector2Array()
var _save_fraction := 0.0
var _flash := 0.0
var _jackpot := 0.0
var _time := 0.0
var _redraw_elapsed := 0.0
## Estado de las reglas (si existen). `_size_mix`: -1 chica, 0 normal, 1 grande; se interpola despacio.
var _size_state := SIZE_NORMAL
var _size_mix := 0.0
var _lock_lit := false
var _tea_party := false
var _tea_mix := 0.0


func _ready() -> void:
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Noto Serif", "DejaVu Serif", "serif"])
	_font.font_weight = 700
	_build_field()
	_ambient = Ambient.new()
	_ambient.name = "Ambient"
	_ambient.art = self
	add_child(_ambient)
	var rules := get_node_or_null("../AliceRules")
	if rules:
		for pair in [["size_changed", _on_size_changed], ["lock_lit_changed", _on_lock_lit_changed],
				["tea_party_started", _on_tea_started], ["tea_party_ended", _on_tea_ended],
				["cards_completed", _on_cards_completed], ["ball_locked", _on_ball_locked],
				["cheshire_hit", _on_cheshire_hit]]:
			if rules.has_signal(pair[0]):
				rules.connect(pair[0], pair[1])
		# Leer el estado inicial permite incorporar el arte con reglas ya activas.
		for property in rules.get_property_list():
			match property.name:
				"size_state":
					_size_state = clampi(int(rules.get("size_state")), 0, 2)
				"lock_lit":
					_lock_lit = bool(rules.get("lock_lit"))
				"tea_party":
					_tea_party = bool(rules.get("tea_party"))
		_size_mix = _size_target()
		_tea_mix = 1.0 if _tea_party else 0.0
	set_process(not Engine.is_editor_hint())


func pulse_score() -> void:
	_flash = 1.0
	_redraw_ambient()


func flash_jackpot() -> void:
	_jackpot = 1.0
	_redraw_ambient()


func set_ball_save_fraction(fraction: float) -> void:
	_save_fraction = clampf(fraction, 0.0, 1.0)
	_redraw_ambient()


func _redraw_ambient() -> void:
	if _ambient:
		_ambient.queue_redraw()


func _size_target() -> float:
	return -1.0 if _size_state == SIZE_SMALL else (1.0 if _size_state == SIZE_BIG else 0.0)


func _on_size_changed(state: int) -> void:
	_size_state = clampi(state, 0, 2)
	_flash = 1.0
	_redraw_ambient()


func _on_lock_lit_changed(lit: bool) -> void:
	_lock_lit = lit
	_redraw_ambient()


func _on_tea_started() -> void:
	_tea_party = true
	_jackpot = maxf(_jackpot, 0.6)


func _on_tea_ended() -> void:
	_tea_party = false


func _on_cards_completed() -> void:
	_flash = 1.0


func _on_ball_locked(_count: int) -> void:
	_flash = 1.0


func _on_cheshire_hit() -> void:
	_flash = maxf(_flash, 0.6)


func _process(delta: float) -> void:
	_time += delta
	_flash = move_toward(_flash, 0.0, delta * 2.0)
	_jackpot = move_toward(_jackpot, 0.0, delta * 0.6)
	_size_mix = move_toward(_size_mix, _size_target(), delta * 1.6)
	_tea_mix = move_toward(_tea_mix, 1.0 if _tea_party else 0.0, delta * 0.5)
	_redraw_elapsed += delta
	if _redraw_elapsed >= 1.0 / REDRAW_HZ:
		_redraw_elapsed = 0.0
		_redraw_ambient()


# ---------------------------------------------------------------- geometría cacheada

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
		var y0 := BAND_TOP + i * BAND_STEP
		var clipped := Geometry2D.intersect_polygons(_field, PackedVector2Array([Vector2(0, y0), Vector2(720, y0),
			Vector2(720, y0 + BAND_STEP + 1.0), Vector2(0, y0 + BAND_STEP + 1.0)]))
		if not clipped.is_empty():
			_bands.append(clipped[0])
			_band_colors.append(_garden_color(y0 + BAND_STEP * 0.5))
	# Cielo grabado con líneas horizontales; trama cruzada diagonal muy tenue en todo el campo.
	_sky_lines = _clip_lines(Rect2(0, 126, 720, 330), 0.0, 7.0)
	_cross_lines = _clip_lines(Rect2(0, 126, 720, FIELD_BOTTOM - 126), 1.0, 26.0)
	_cross_lines.append_array(_clip_lines(Rect2(0, 126, 720, FIELD_BOTTOM - 126), -1.0, 26.0))
	_lane = _clip_rect(Rect2(664, 430, 60, FIELD_BOTTOM - 430))
	_apron = _clip_rect(Rect2(0, 1320, 664, 130))
	_stars = PackedVector2Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1865
	var title_area := Rect2(TITLE_AT - Vector2(150, 42), Vector2(300, 88))
	while _stars.size() < 34:
		var p := Vector2(rng.randf_range(40, 690), rng.randf_range(150, 360))
		if Geometry2D.is_point_in_polygon(p, _field) and not title_area.has_point(p) \
				and p.distance_to(Vector2(130, 270)) > 56.0:
			_stars.append(p)
	_hedge = PackedVector2Array()
	for i in 29:
		var t := PI + PI * (i + 0.5) / 29.0
		_hedge.append(ARCH_CENTER + Vector2.from_angle(t) * (ARCH_RADIUS - 13.0))


func _clip_rect(rect: Rect2) -> PackedVector2Array:
	var points := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end,
		Vector2(rect.position.x, rect.end.y)])
	var clipped := Geometry2D.intersect_polygons(_field, points)
	return clipped[0] if not clipped.is_empty() else points


## Segmentos de rayado (slope 0 = horizontales, +-1 = diagonales) recortados al campo, listos para draw_multiline.
func _clip_lines(area: Rect2, slope: float, step: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var area_poly := Geometry2D.intersect_polygons(_field, PackedVector2Array([area.position,
		Vector2(area.end.x, area.position.y), area.end, Vector2(area.position.x, area.end.y)]))
	if area_poly.is_empty():
		return out
	var region: PackedVector2Array = area_poly[0]
	var lines: Array[PackedVector2Array] = []
	if slope == 0.0:
		var y := area.position.y
		while y < area.end.y:
			lines.append(PackedVector2Array([Vector2(area.position.x, y), Vector2(area.end.x, y)]))
			y += step
	else:
		var x := area.position.x - area.size.y
		while x < area.end.x:
			var a := Vector2(x, area.position.y)
			var b := Vector2(x + area.size.y, area.end.y)
			if slope < 0.0:
				a = Vector2(x + area.size.y, area.position.y)
				b = Vector2(x, area.end.y)
			lines.append(PackedVector2Array([a, b]))
			x += step
	for line in lines:
		for piece in Geometry2D.clip_polyline_with_polygon(line, region):
			if piece.size() >= 2:
				out.append(piece[0])
				out.append(piece[piece.size() - 1])
	return out


func _garden_color(y: float) -> Color:
	# Cielo de jardín nocturno: verdoso profundo arriba, más claro al horizonte y sobrio bajo las piezas.
	var top := Color("#0c1514")
	var horizon := Color("#1c3330")
	var low := GARDEN
	var bottom := Color("#0d1716")
	if y < 380.0:
		return top.lerp(horizon, smoothstep(126.0, 380.0, y))
	if y < 700.0:
		return horizon.lerp(low, smoothstep(380.0, 700.0, y))
	return low.lerp(bottom, smoothstep(700.0, 1150.0, y))


func _arch_half_width(y: float) -> float:
	if y >= ARCH_CENTER.y:
		return ARCH_RADIUS
	var dy := ARCH_CENTER.y - y
	return sqrt(maxf(0.0, ARCH_RADIUS * ARCH_RADIUS - dy * dy))


# ---------------------------------------------------------------- capa estática

func _draw() -> void:
	if _bands.is_empty():
		return
	# Gabinete fuera del contorno: tinta con filete de oro.
	draw_rect(Rect2(0, 100, 720, 1400), Color("#080c0b"))
	draw_rect(Rect2(0, 115, 11, 1330), Color("#14110f"))
	draw_rect(Rect2(709, 115, 11, 1330), Color("#14110f"))
	draw_line(Vector2(8, 116), Vector2(8, 1450), Color(GOLD, 0.4), 1.0)
	draw_line(Vector2(713, 116), Vector2(713, 1450), Color(GOLD, 0.4), 1.0)
	for x in [5, 715]:
		for y in [142, 452, 780, 1120, 1428]:
			draw_circle(Vector2(x, y), 3.0, Color(GOLD, 0.45), true, -1.0, true)
	for i in _bands.size():
		draw_colored_polygon(_bands[i], _band_colors[i])
	# Rayado de grabado: cielo horizontal, trama diagonal cruzada.
	draw_multiline(_sky_lines, Color(PAPER, 0.045), 1.0, true)
	draw_multiline(_cross_lines, Color(PAPER, 0.022), 1.0, true)
	_draw_sky()
	_draw_hedge()
	_draw_floor()
	_draw_title()
	_draw_lane()
	_draw_apron()


func _draw_sky() -> void:
	# Estrellas en cruz fina (como puntos de buril).
	for i in _stars.size():
		var p := _stars[i]
		var big := i % 4 == 0
		var arm := 3.2 if big else 1.8
		var c := Color(PAPER, 0.5 if big else 0.28)
		draw_line(p - Vector2(arm, 0), p + Vector2(arm, 0), c, 1.0, true)
		draw_line(p - Vector2(0, arm), p + Vector2(0, arm), c, 1.0, true)
	# Luna creciente con halo, rayada por dentro.
	var moon := Vector2(130, 270)
	for i in 4:
		draw_circle(moon, 70.0 - i * 12.0, Color(PAPER, 0.018 + i * 0.006), true, -1.0, true)
	var crescent := PackedVector2Array()
	var radius := 34.0
	var cut := 28.0
	var shift := 14.0
	var tip_x := (shift * shift + radius * radius - cut * cut) / (2.0 * shift)
	var tip_angle := acos(tip_x / radius)
	for i in 17:
		crescent.append(Vector2.from_angle(lerpf(tip_angle, TAU - tip_angle, i / 16.0)) * radius)
	var cut_angle := atan2(radius * sin(tip_angle), tip_x - shift)
	for i in range(1, 16):
		crescent.append(Vector2(shift, 0) + Vector2.from_angle(lerpf(TAU - cut_angle, cut_angle, i / 16.0)) * cut)
	draw_set_transform(moon, -0.35, Vector2.ONE)
	draw_colored_polygon(crescent, Color(PAPER, 0.92))
	draw_polyline(crescent + PackedVector2Array([crescent[0]]), Color(INK, 0.7), 1.2, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Cartel de madriguera tenue: reloj de bolsillo colgando (guiño a la historia), sin figuras de otras versiones.
	var clock := Vector2(590, 262)
	draw_arc(clock, 20, 0.0, TAU, 32, Color(GOLD, 0.2), 1.4, true)
	draw_arc(clock, 16, 0.0, TAU, 28, Color(GOLD, 0.1), 1.0, true)
	for h in 12:
		var d := Vector2.from_angle(TAU * h / 12.0 - PI / 2.0)
		draw_line(clock + d * 13.0, clock + d * 16.0, Color(GOLD, 0.2), 1.0, true)
	draw_line(clock, clock + Vector2(0, -10), Color(GOLD, 0.25), 1.2, true)
	draw_line(clock, clock + Vector2(8, 3), Color(GOLD, 0.25), 1.2, true)


func _draw_hedge() -> void:
	# Seto de jardín: festón de matas oscuras sobre el arco superior y laterales, con rayado de hojas.
	for p in _hedge:
		draw_circle(p, 17.0, Color("#0a1312"), true, -1.0, true)
		draw_arc(p, 17.0, 0.0, TAU, 14, Color(PAPER, 0.07), 1.0, true)
	for y in range(520, 960, 34):
		for x in [30.0, 642.0]:
			draw_circle(Vector2(x, y), 14.0, Color("#0a1312", 0.85), true, -1.0, true)
			draw_arc(Vector2(x, y), 14.0, 0.0, TAU, 12, Color(PAPER, 0.05), 1.0, true)
	for i in _hedge.size():
		if i % 3 == 0:
			# Rosas del reino: pequeñas, rojas y tenues.
			draw_circle(_hedge[i] + Vector2(2, 6), 3.2, Color(QUEEN, 0.5), true, -1.0, true)
			draw_arc(_hedge[i] + Vector2(2, 6), 3.2, 0.0, TAU, 8, Color(INK, 0.6), 1.0, true)


func _draw_floor() -> void:
	# Marcas bajo las piezas: nunca compiten con las lámparas ni con la bola.
	for p in [Vector2(210, 610), Vector2(462, 610), Vector2(336, 530)]:
		draw_circle(p, 62, Color(QUEEN, 0.05), true, -1.0, true)
		# Anillo de hadas: pequeños puntos alrededor del hongo.
		for k in 14:
			draw_circle(p + Vector2.from_angle(TAU * k / 14.0) * 57.0, 1.6, Color(PAPER, 0.16), true, -1.0, true)
	# Mesa del té: aro con marcas de reloj detrás de la Tetera.
	var tea := Vector2(336, 830)
	draw_arc(tea, 108, 0, TAU, 56, Color(GOLD, 0.1), 1.5, true)
	draw_arc(tea, 92, 0, TAU, 56, Color(PAPER, 0.06), 1.0, true)
	for i in 12:
		var dir := Vector2.from_angle(TAU * i / 12.0)
		draw_line(tea + dir * 96.0, tea + dir * 106.0, Color(GOLD, 0.12), 1.2, true)
	# Baldosas de ajedrez muy suaves hacia el fondo (sin invadir la franja de lamparitas en y=1155).
	for row in 5:
		var y := 920.0 + row * 40.0
		for col in range(-5, 6):
			if (row + col) % 2 == 0:
				var x := 336.0 + col * 54.0
				if Rect2(80, 0, 512, 2000).has_point(Vector2(x, y)) and not Rect2(260, 770, 152, 120).has_point(Vector2(x, y)):
					draw_rect(Rect2(x - 27.0, y, 54.0, 40.0), Color(PAPER, 0.018))
	# Cuatro palos grabados, apenas insinuados, en las esquinas del banco de naipes.
	for k in 4:
		draw_set_transform(Vector2(150 + k * 124, 505), 0.0, Vector2.ONE)
		AliceVisuals._suit(self, k, 9.0, Color(PAPER, 0.07), Color(PAPER, 0.0))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_title() -> void:
	_draw_centered(TITLE, TITLE_AT, TITLE_SIZE, PAPER)
	_draw_centered(SUBTITLE, SUBTITLE_AT, SUBTITLE_SIZE, Color(GOLD, 0.92))
	for side in [-1.0, 1.0]:
		var base := SUBTITLE_AT + Vector2(side * 145, -5.5)
		draw_line(base, base + Vector2(side * 12, 0), Color(GOLD, 0.5), 1.0, true)
		draw_colored_polygon(PackedVector2Array([base + Vector2(0, -3), base + Vector2(side * 4, 0), base + Vector2(0, 3),
			base + Vector2(-side * 4, 0)]), Color(QUEEN, 0.9))


func _draw_lane() -> void:
	draw_colored_polygon(_lane, Color("#0d1413"))
	for i in 10:
		draw_rect(Rect2(668, 900 + i * 53, 36, 54), Color(QUEEN, 0.012 + 0.04 * float(i) / 9.0))
	draw_line(Vector2(672, 449), Vector2(672, 1432), Color(GOLD, 0.6), 2, true)
	draw_line(Vector2(700, 449), Vector2(700, 1432), Color(PAPER, 0.25), 2, true)
	for y in range(487, 1268, 44):
		draw_line(Vector2(678, y + 5), Vector2(686, y - 2), Color(GOLD, 0.45), 1.5, true)
		draw_line(Vector2(686, y - 2), Vector2(694, y + 5), Color(GOLD, 0.45), 1.5, true)


func _draw_apron() -> void:
	draw_colored_polygon(_apron, Color("#111a19"))
	draw_line(Vector2(16, 1322), Vector2(656, 1322), Color(GOLD, 0.16), 1.0)
	draw_line(Vector2(16, FIELD_BOTTOM - 1.0), Vector2(707, FIELD_BOTTOM - 1.0), Color(GOLD, 0.5), 2)
	for x in [60.0, 612.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(x, 1350), Vector2(x + 7, 1357), Vector2(x, 1364),
			Vector2(x - 7, 1357)]), Color(QUEEN, 0.8))


func _draw_centered(label: String, at: Vector2, size: int, color: Color) -> void:
	var width := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var start := at - Vector2(width * 0.5, 0)
	draw_string_outline(_font, start, label, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 5, INK)
	draw_string(_font, start, label, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


# ---------------------------------------------------------------- capa dinámica

## Marco y viñeta del tamaño, luciérnagas, salvabolas y destellos. La redibuja el arte a 20 Hz como máximo.
class Ambient extends Node2D:
	var art: Node2D

	func _draw() -> void:
		if art == null or art._field.is_empty():
			return
		_draw_size_frame()
		_draw_fireflies()
		_draw_effects()
		_draw_save_plate()

	func _draw_size_frame() -> void:
		var mix: float = art._size_mix
		var amount := absf(mix)
		var closed: PackedVector2Array = art._field + PackedVector2Array([art._field[0]])
		# Normal: filete fino de sepia y oro. Chica: marco verde té grueso con viñeta que se cierra hacia dentro.
		# Grande: marco rojo Reina más ancho y viñeta suave, para que se lea a primera vista.
		var accent: Color = art.TEA if mix < 0.0 else art.QUEEN
		var base: Color = art.SEPIA.lerp(art.GOLD, 0.5)
		var frame_color := base.lerp(accent, clampf(amount * 1.4, 0.0, 1.0))
		var frame_width := lerpf(2.0, 5.0 if mix < 0.0 else 8.0, amount)
		if amount > 0.02:
			var vignette_alpha := (0.2 if mix < 0.0 else 0.12) * amount
			var vignette_width := 110.0 if mix < 0.0 else 52.0
			draw_polyline(closed, Color(accent.darkened(0.4), vignette_alpha * 0.5), vignette_width, true)
			draw_polyline(closed, Color(accent.darkened(0.2), vignette_alpha * 0.8), vignette_width * 0.5, true)
			draw_polyline(closed, Color(accent, vignette_alpha), vignette_width * 0.2, true)
		draw_polyline(closed, Color(art.INK, 0.8), frame_width + 3.0, true)
		draw_polyline(closed, Color(frame_color, 0.85), frame_width, true)
		draw_polyline(closed, Color(art.PAPER, 0.18), 1.0, true)
		# Tea party: el marco se dora suavemente (alfa continuo, sin parpadeo).
		if art._tea_mix > 0.01:
			draw_polyline(closed, Color(art.GOLD, 0.35 * art._tea_mix * (0.8 + 0.2 * sin(art._time * 1.6))), frame_width + 4.0, true)
		if amount > 0.3:
			var label: String = "CHICA" if mix < 0.0 else "GRANDE"
			var width: float = art._font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE_LABEL_SIZE).x
			var start := SIZE_LABEL_AT - Vector2(width * 0.5, 0)
			draw_string_outline(art._font, start, label, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE_LABEL_SIZE, 4, art.INK)
			draw_string(art._font, start, label, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE_LABEL_SIZE,
				Color(accent.lightened(0.35), amount))

	func _draw_fireflies() -> void:
		# Ocho luciérnagas lentas por los lados: alfa suave y continuo, lejos del pasillo central y de las lamparitas.
		for i in 8:
			var t: float = art._time * 0.18 + i * 1.7
			var side := -1.0 if i % 2 == 0 else 1.0
			var p := Vector2(336.0 + side * (240.0 + 50.0 * sin(t * 1.3 + i)), 330.0 + fposmod(i * 131.0 + t * 24.0, 780.0))
			if absf(p.x - 336.0) < 110.0 or p.y > 1110.0:
				continue
			var glow := 0.5 + 0.5 * sin(art._time * 0.9 + i * 2.1)
			draw_circle(p, 5.0, Color(art.GOLD, 0.04 + 0.04 * glow), true, -1.0, true)
			draw_circle(p, 1.4, Color(art.PAPER, 0.25 + 0.25 * glow), true, -1.0, true)

	func _draw_effects() -> void:
		if art._flash > 0.01:
			var closed: PackedVector2Array = art._field + PackedVector2Array([art._field[0]])
			draw_polyline(closed, Color(art.PAPER, art._flash * 0.1), 6.0, true)
		if art._jackpot > 0.01:
			var j: float = art._jackpot
			draw_arc(Vector2(336, 830), lerpf(190.0, 80.0, j), 0.0, TAU, 48, Color(art.GOLD, j * 0.28), 3.0, true)
			draw_arc(Vector2(336, 830), lerpf(150.0, 70.0, j), 0.0, TAU, 48, Color(art.TEA.lightened(0.3), j * 0.2), 2.0, true)
		if art._lock_lit:
			draw_arc(Vector2(336, 300), 58.0, 0.0, TAU, 36, Color(art.GOLD, 0.14 + 0.05 * sin(art._time * 2.0)), 2.0, true)

	func _draw_save_plate() -> void:
		var fraction: float = art._save_fraction
		var lit := fraction > 0.0
		draw_rect(Rect2(264, 1335, 144, 47), Color("#090d0c"))
		draw_rect(Rect2(264, 1335, 144, 47), Color(art.GOLD, 0.55), false, 2.0)
		var label := "SALVABOLAS"
		var width: float = art._font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		var tint: Color = art.PAPER.lerp(Color.WHITE, art._flash * 0.5) if lit else Color("#777a7a")
		draw_string_outline(art._font, Vector2(336 - width * 0.5, 1360), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 4, art.INK)
		draw_string(art._font, Vector2(336 - width * 0.5, 1360), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, tint)
		draw_rect(Rect2(282, 1367, 108, 3), Color("#2a2f2e"))
		draw_rect(Rect2(282, 1367, 108.0 * fraction, 3), art.TEA.lightened(0.25))
		if art._flash > 0.0:
			draw_line(Vector2(266, 1338), Vector2(406, 1338), Color(art.PAPER, art._flash * 0.5), 3.0, true)
