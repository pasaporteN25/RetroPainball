class_name AliceVisuals
extends RefCounted
## Dibujo de las piezas de la mesa Alicia (A-08 / S-09). Lo llaman desde el `_draw()` de cada pieza
## (scripts/table/alice_*.gd, las escribe lógica). Todo se dibuja centrado en el origen local de `item`.
## Firmas = contrato entre lógica y arte: no cambiar (ver docs/mesas/ALICIA.md y docs/ARTE.md, "Alicia").
##
## Estilo: grabado original (tinta, rayado cruzado, brillo suave), en la línea de los grabados de Tenniel
## (dominio público) pero dibujado en código. Nada de Disney ni de otras adaptaciones.
## Rendimiento: solo primitivas (sin texturas ni fuentes); cada pieza usa pocas llamadas de dibujo.

const SUIT_SPADES := 0
const SUIT_HEARTS := 1
const SUIT_DIAMONDS := 2
const SUIT_CLUBS := 3
const SIZE_DRINK := 0
const SIZE_EAT := 1

const INK := Color("#14110f")
const GARDEN := Color("#12201f")
const PAPER := Color("#ece2c8")
const SEPIA := Color("#6b5436")
const QUEEN := Color("#b3262e")
const TEA := Color("#2f7f86")
const GOLD := Color("#c9a24a")
const LILAC := Color("#7a5fa8")


# ---------------------------------------------------------------- utilidades de grabado

## Rayado paralelo dentro de un círculo (cuerdas a `angle`, separadas `step` px).
static func hatch_circle(item: CanvasItem, center: Vector2, radius: float, angle: float, step: float,
		color: Color, width := 1.0) -> void:
	var dir := Vector2.from_angle(angle)
	var normal := dir.orthogonal()
	var segments := PackedVector2Array()
	var d := -radius + step * 0.5
	while d < radius:
		var half := sqrt(maxf(0.0, radius * radius - d * d))
		segments.append(center + normal * d - dir * half)
		segments.append(center + normal * d + dir * half)
		d += step
	if not segments.is_empty():
		item.draw_multiline(segments, color, width, true)


## Rayado a 45 grados dentro de un rectángulo (`slope` +1 o -1), separado `step` px en horizontal.
static func hatch_rect(item: CanvasItem, rect: Rect2, slope: float, step: float, color: Color, width := 1.0) -> void:
	var segments := PackedVector2Array()
	var x := rect.position.x - rect.size.y
	while x < rect.end.x:
		var a := Vector2(x, rect.position.y)
		var b := Vector2(x + rect.size.y, rect.end.y)
		if slope < 0.0:
			a = Vector2(x + rect.size.y, rect.position.y)
			b = Vector2(x, rect.end.y)
		var clipped := _clip_x(a, b, rect.position.x, rect.end.x)
		if clipped.size() == 2:
			segments.append(clipped[0])
			segments.append(clipped[1])
		x += step
	if not segments.is_empty():
		item.draw_multiline(segments, color, width, true)


static func _clip_x(a: Vector2, b: Vector2, x0: float, x1: float) -> PackedVector2Array:
	if is_equal_approx(a.x, b.x):
		return PackedVector2Array([a, b]) if a.x >= x0 and a.x <= x1 else PackedVector2Array()
	var t0 := 0.0
	var t1 := 1.0
	var ta := (x0 - a.x) / (b.x - a.x)
	var tb := (x1 - a.x) / (b.x - a.x)
	t0 = maxf(t0, minf(ta, tb))
	t1 = minf(t1, maxf(ta, tb))
	if t0 >= t1:
		return PackedVector2Array()
	return PackedVector2Array([a.lerp(b, t0), a.lerp(b, t1)])


## Polígono relleno con contorno de tinta.
static func _inked(item: CanvasItem, points: PackedVector2Array, fill: Color, line := INK, width := 1.6) -> void:
	item.draw_colored_polygon(points, fill)
	item.draw_polyline(points + PackedVector2Array([points[0]]), line, width, true)


static func _disc(item: CanvasItem, center: Vector2, radius: float, fill: Color, line := INK, width := 1.6) -> void:
	item.draw_circle(center, radius, fill, true, -1.0, true)
	item.draw_arc(center, radius, 0.0, TAU, 28, line, width, true)


## Brillo suave: tres halos concéntricos muy tenues (sin texturas).
static func _glow(item: CanvasItem, center: Vector2, radius: float, color: Color, strength: float) -> void:
	for i in 3:
		item.draw_circle(center, radius * (1.0 + 0.22 * i), Color(color, strength * (0.16 - 0.045 * i)), true, -1.0, true)


static func _heart(scale_factor: float, flip: bool) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 24:
		var t := TAU * i / 24.0
		var p := Vector2(16.0 * pow(sin(t), 3.0),
			-(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))) / 17.0
		p.y += 0.08
		points.append(Vector2(p.x, -p.y if flip else p.y) * scale_factor)
	return points


## Palo en el origen. `s` ~ medio ancho en px. Los cuatro son siluetas originales de trazo simple.
static func _suit(item: CanvasItem, suit: int, s: float, color: Color, line_color: Color) -> void:
	match suit:
		SUIT_HEARTS:
			_inked(item, _heart(s, false), color, line_color, 1.2)
		SUIT_SPADES:
			_inked(item, _heart(s, true), color, line_color, 1.2)
			item.draw_colored_polygon(PackedVector2Array([Vector2(-0.12 * s, 0.55 * s), Vector2(-0.34 * s, 1.05 * s),
				Vector2(0.34 * s, 1.05 * s), Vector2(0.12 * s, 0.55 * s)]), color)
		SUIT_DIAMONDS:
			_inked(item, PackedVector2Array([Vector2(0, -1.15 * s), Vector2(0.75 * s, 0), Vector2(0, 1.15 * s),
				Vector2(-0.75 * s, 0)]), color, line_color, 1.2)
		_:
			for p in [Vector2(0, -0.48 * s), Vector2(-0.5 * s, 0.28 * s), Vector2(0.5 * s, 0.28 * s)]:
				item.draw_circle(p, 0.42 * s, color, true, -1.0, true)
			item.draw_colored_polygon(PackedVector2Array([Vector2(-0.1 * s, 0.2 * s), Vector2(-0.32 * s, 1.05 * s),
				Vector2(0.32 * s, 1.05 * s), Vector2(0.1 * s, 0.2 * s)]), color)


# ---------------------------------------------------------------- piezas

## Naipe del banco. `flipped` = ya dado vuelta (encendido). `size` = tamaño del blanco en px.
static func draw_card(item: CanvasItem, suit: int, flipped: bool, size: Vector2) -> void:
	var rect := Rect2(-size / 2.0, size)
	var r := minf(size.x, size.y) * 0.12
	var body := PackedVector2Array([rect.position + Vector2(r, 0), Vector2(rect.end.x - r, rect.position.y),
		Vector2(rect.end.x, rect.position.y + r), Vector2(rect.end.x, rect.end.y - r),
		Vector2(rect.end.x - r, rect.end.y), Vector2(rect.position.x + r, rect.end.y),
		Vector2(rect.position.x, rect.end.y - r), Vector2(rect.position.x, rect.position.y + r)])
	var red_suit := suit == SUIT_HEARTS or suit == SUIT_DIAMONDS
	var s := minf(size.x, size.y) * 0.27
	if flipped:
		_glow(item, Vector2.ZERO, maxf(size.x, size.y) * 0.5, GOLD, 1.0)
		_inked(item, body, PAPER, INK, 2.0)
		hatch_rect(item, rect.grow(-3.0), 1.0, 5.0, Color(SEPIA, 0.12), 0.8)
		var tone := QUEEN if red_suit else INK
		item.draw_rect(rect.grow(-size.x * 0.1), Color(SEPIA, 0.55), false, 1.0)
		_suit(item, suit, s * 1.15, tone, INK)
		# Índices en las esquinas (el de abajo girado 180 grados), como en una baraja impresa.
		var corner := Vector2(-size.x * 0.28, -size.y * 0.33)
		item.draw_set_transform(corner, 0.0, Vector2.ONE)
		_suit(item, suit, s * 0.32, tone, tone)
		item.draw_set_transform(-corner, PI, Vector2.ONE)
		_suit(item, suit, s * 0.32, tone, tone)
		item.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		# Dorso: tinta sepia con celosía de rombos y el sello del palo, apagado.
		_inked(item, body, SEPIA.darkened(0.35), INK, 2.0)
		item.draw_rect(rect.grow(-size.x * 0.09), Color(PAPER, 0.35), false, 1.0)
		hatch_rect(item, rect.grow(-size.x * 0.12), 1.0, 6.0, Color(PAPER, 0.16), 0.9)
		hatch_rect(item, rect.grow(-size.x * 0.12), -1.0, 6.0, Color(PAPER, 0.16), 0.9)
		item.draw_circle(Vector2.ZERO, s * 0.95, Color(INK, 0.55), true, -1.0, true)
		_suit(item, suit, s * 0.7, Color(QUEEN, 0.85) if red_suit else Color(PAPER, 0.5), Color(INK, 0.0))


## Blanco BEBÉ-ME (SIZE_DRINK) o CÓMEME (SIZE_EAT). `active` = es el tamaño actual.
static func draw_size_target(item: CanvasItem, kind: int, active: bool, radius: float) -> void:
	var accent := TEA if kind == SIZE_DRINK else QUEEN
	if active:
		_glow(item, Vector2.ZERO, radius, accent.lightened(0.25), 1.0)
	_disc(item, Vector2.ZERO, radius, accent.darkened(0.1 if active else 0.45).lerp(INK, 0.35), INK, 2.0)
	hatch_circle(item, Vector2.ZERO, radius - 2.0, -PI / 4.0, 4.0, Color(INK, 0.35), 0.9)
	item.draw_arc(Vector2.ZERO, radius - 3.0, 0.0, TAU, 28, Color(GOLD if active else SEPIA, 0.9), 1.4, true)
	var u := radius / 24.0
	if kind == SIZE_DRINK:
		# Frasquito con etiqueta y cuello fino.
		var glass := PackedVector2Array([Vector2(-3, -15), Vector2(3, -15), Vector2(3, -8), Vector2(10, 0),
			Vector2(10, 13), Vector2(6, 16), Vector2(-6, 16), Vector2(-10, 13), Vector2(-10, 0), Vector2(-3, -8)])
		for i in glass.size():
			glass[i] *= u
		_inked(item, glass, Color(TEA.lightened(0.35 if active else 0.0), 0.9), PAPER, 1.4)
		item.draw_rect(Rect2(-4 * u, -18 * u, 8 * u, 4 * u), SEPIA)
		item.draw_rect(Rect2(-8 * u, 3 * u, 16 * u, 8 * u), PAPER)
		item.draw_line(Vector2(-5, 7) * u, Vector2(5, 7) * u, INK, 1.0)
		item.draw_line(Vector2(-3, 9.5) * u, Vector2(3, 9.5) * u, INK, 1.0)
	else:
		# Pastelillo con glaseado y grosellas.
		var cake := PackedVector2Array([Vector2(-14, 12), Vector2(-14, -2), Vector2(-9, -9), Vector2(9, -9),
			Vector2(14, -2), Vector2(14, 12)])
		for i in cake.size():
			cake[i] *= u
		_inked(item, cake, SEPIA.lightened(0.25), PAPER, 1.4)
		item.draw_rect(Rect2(-14 * u, -2 * u, 28 * u, 5 * u), PAPER)
		for x in [-8.0, 0.0, 8.0]:
			item.draw_circle(Vector2(x, -5.5) * u, 1.8 * u, QUEEN.lightened(0.2), true, -1.0, true)
		item.draw_line(Vector2(-14, 12) * u, Vector2(14, 12) * u, PAPER, 1.6, true)


## Gato de Cheshire. `visibility` 0..1: 1 = visible (golpeable), 0 = solo queda la sonrisa tenue.
## La transparencia es continua: el desvanecimiento no parpadea aunque se redibuje a cualquier ritmo.
static func draw_cheshire(item: CanvasItem, radius: float, visibility: float) -> void:
	var v := clampf(visibility, 0.0, 1.0)
	var u := radius / 30.0
	var smile_alpha := 0.4 + 0.6 * v
	if v > 0.02:
		var a := v
		# Orejas, cabeza y rayas de pelaje (rayado de grabado).
		for side in [-1.0, 1.0]:
			var ear := PackedVector2Array([Vector2(side * 10, -17) * u, Vector2(side * 24, -34) * u, Vector2(side * 27, -10) * u])
			item.draw_colored_polygon(ear, Color(LILAC.darkened(0.2), a))
			item.draw_polyline(ear, Color(INK, a), 1.4 * u, true)
		item.draw_circle(Vector2.ZERO, radius, Color(LILAC.darkened(0.15), a), true, -1.0, true)
		hatch_circle(item, Vector2.ZERO, radius - 1.0, PI / 3.0, 5.0 * u, Color(INK, 0.28 * a), 1.0)
		hatch_circle(item, Vector2.ZERO, radius - 1.0, -PI / 6.0, 9.0 * u, Color(INK, 0.16 * a), 1.0)
		item.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(INK, a), 1.8, true)
		for stripe in [[-14.0, -22.0], [0.0, -26.0], [14.0, -22.0]]:
			item.draw_line(Vector2(stripe[0], stripe[1]) * u, Vector2(stripe[0] * 0.8, stripe[1] + 8.0) * u,
				Color(INK, 0.6 * a), 1.6 * u, true)
		# Ojos oblicuos amarillos con pupila vertical, nariz y bigotes.
		for side in [-1.0, 1.0]:
			var eye := Vector2(side * 11, -7) * u
			item.draw_circle(eye, 5.2 * u, Color(GOLD.lightened(0.2), a), true, -1.0, true)
			item.draw_arc(eye, 5.2 * u, 0.0, TAU, 14, Color(INK, a), 1.2, true)
			item.draw_line(eye + Vector2(0, -4) * u, eye + Vector2(0, 4) * u, Color(INK, a), 2.0 * u, true)
			for k in 2:
				item.draw_line(Vector2(side * 14, 5 + k * 3) * u, Vector2(side * 36, 1 + k * 8) * u, Color(PAPER, 0.5 * a), 1.0, true)
		item.draw_colored_polygon(PackedVector2Array([Vector2(-2.5, 2) * u, Vector2(2.5, 2) * u, Vector2(0, 5) * u]),
			Color(QUEEN.lightened(0.15), a))
	else:
		# Solo la sonrisa: un aro apenas visible marca dónde está el blanco.
		item.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(LILAC, 0.1), 1.0, true)
	# Sonrisa ancha de media luna con dientes; es lo último que se apaga.
	var smile := PackedVector2Array()
	for i in 13:
		var t := lerpf(0.18 * PI, 0.82 * PI, i / 12.0)
		smile.append(Vector2(cos(t) * 21.0, sin(t) * 13.0 + 3.0) * u)
	for i in 13:
		var t := lerpf(0.82 * PI, 0.18 * PI, i / 12.0)
		smile.append(Vector2(cos(t) * 21.0, sin(t) * 7.0 + 3.0) * u)
	item.draw_colored_polygon(smile, Color(INK, smile_alpha * 0.9))
	item.draw_polyline(smile + PackedVector2Array([smile[0]]), Color(PAPER, smile_alpha), 1.6, true)
	for i in range(1, 12, 2):
		var t := lerpf(0.18 * PI, 0.82 * PI, i / 12.0)
		item.draw_line(Vector2(cos(t) * 21.0, sin(t) * 13.0 + 3.0) * u, Vector2(cos(t) * 21.0, sin(t) * 7.0 + 3.0) * u,
			Color(PAPER, smile_alpha * 0.9), 1.4, true)


## Hongo (bumper). `flash` 0..1 = destello al golpe. Solo se dibuja; la física no cambia.
static func draw_mushroom(item: CanvasItem, radius: float, flash: float) -> void:
	var f := clampf(flash, 0.0, 1.0)
	var u := radius / 36.0
	if f > 0.02:
		_glow(item, Vector2.ZERO, radius, GOLD.lerp(Color.WHITE, 0.4), f)
	# Pie con rayado vertical.
	var stem := PackedVector2Array([Vector2(-9, -2), Vector2(9, -2), Vector2(12, 28), Vector2(-12, 28)])
	for i in stem.size():
		stem[i] *= u
	_inked(item, stem, PAPER.darkened(0.08), INK, 1.6)
	for x in [-6.0, -2.0, 2.0, 6.0]:
		item.draw_line(Vector2(x, 2) * u, Vector2(x * 1.15, 26) * u, Color(SEPIA, 0.4), 1.0, true)
	item.draw_line(Vector2(-14, 28) * u, Vector2(14, 28) * u, INK, 1.8 * u, true)
	# Sombrero: media elipse con borde, laminillas y lunares.
	var cap := PackedVector2Array()
	for i in 17:
		var t := PI + PI * i / 16.0
		cap.append(Vector2(cos(t) * 34.0, sin(t) * 28.0 + 2.0) * u)
	_inked(item, cap, QUEEN.lerp(Color(1, 0.86, 0.6), f * 0.7), INK, 2.0)
	for i in 5:
		var x := -22.0 + i * 11.0
		item.draw_line(Vector2(x, 2) * u, Vector2(x * 0.75, -24.0 + absf(x) * 0.5) * u, Color(INK, 0.28), 1.0, true)
	item.draw_line(Vector2(-34, 2) * u, Vector2(34, 2) * u, INK, 2.2 * u, true)
	for spot in [[-15.0, -10.0, 5.0], [8.0, -16.0, 4.2], [18.0, -5.0, 3.2], [-2.0, -4.0, 2.6]]:
		_disc(item, Vector2(spot[0], spot[1]) * u, spot[2] * u, PAPER, INK, 1.0)
	item.draw_arc(Vector2(-4, 4) * u, 28.0 * u, PI * 1.15, PI * 1.45, 8, Color(PAPER, 0.4), 1.6, true)


## Tetera (jackpot de Té Loco). `lit` = Té Loco activo.
static func draw_teapot(item: CanvasItem, radius: float, lit: bool) -> void:
	var u := radius / 55.0
	if lit:
		_glow(item, Vector2.ZERO, radius, GOLD, 1.0)
	var tone := TEA if lit else TEA.darkened(0.35)
	# Pico, asa y cuerpo (de atrás hacia adelante) con contorno de tinta.
	var spout := PackedVector2Array([Vector2(26, -6) * u, Vector2(50, -26) * u, Vector2(56, -22) * u,
		Vector2(40, 2) * u, Vector2(28, 14) * u])
	_inked(item, spout, tone, INK, 2.0)
	var handle := PackedVector2Array()
	for i in 13:
		var t := -PI * 0.5 + PI * i / 12.0
		handle.append(Vector2(-30.0 - cos(t) * 20.0, sin(t) * 20.0 + 2.0) * u)
	item.draw_polyline(handle, INK, 9.0 * u, true)
	item.draw_polyline(handle, tone.lightened(0.1), 5.0 * u, true)
	var body := PackedVector2Array()
	for i in 28:
		var t := TAU * i / 28.0
		body.append(Vector2(cos(t) * 36.0, sin(t) * 28.0 + 4.0) * u)
	_inked(item, body, tone, INK, 2.2)
	hatch_circle(item, Vector2(0, 4) * u, 27.0 * u, -PI / 4.0, 4.5 * u, Color(INK, 0.3), 1.0)
	# Bandas doradas, medallón y brillo.
	item.draw_arc(Vector2(0, 4) * u, 25.0 * u, PI * 0.15, PI * 0.85, 12, GOLD, 1.8, true)
	item.draw_arc(Vector2(0, 4) * u, 31.0 * u, PI * 0.1, PI * 0.9, 12, Color(GOLD, 0.6), 1.2, true)
	item.draw_circle(Vector2(0, 14) * u, 4.0 * u, PAPER if lit else Color(PAPER, 0.7), true, -1.0, true)
	item.draw_arc(Vector2(-16, -10) * u, 15.0 * u, PI * 1.1, PI * 1.5, 8, Color(PAPER, 0.4), 2.0, true)
	# Tapa con perilla.
	var lid := PackedVector2Array([Vector2(-20, -21) * u, Vector2(-12, -34) * u, Vector2(12, -34) * u, Vector2(20, -21) * u])
	_inked(item, lid, tone.lightened(0.08), INK, 2.0)
	_disc(item, Vector2(0, -38) * u, 4.5 * u, GOLD, INK, 1.6)
	# Vapor: dos volutas finas, más claras con Té Loco.
	for side in [-1.0, 1.0]:
		var wisp := PackedVector2Array()
		for i in 8:
			wisp.append(Vector2(side * 4.0 + sin(i * 0.9 + side) * 5.0, -44.0 - i * 3.6) * u)
		item.draw_polyline(wisp, Color(PAPER, 0.7 if lit else 0.25), 1.4, true)


## Madriguera (plato). `lit` = LOCK encendido.
static func draw_rabbithole(item: CanvasItem, radius: float, lit: bool) -> void:
	# Raíces de árbol alrededor, la boca y espirales de tierra que bajan al fondo.
	for i in 12:
		var dir := Vector2.from_angle(TAU * i / 12.0 + 0.1)
		var bend := dir.orthogonal() * (6.0 if i % 2 == 0 else -6.0)
		item.draw_polyline(PackedVector2Array([dir * radius * 0.92, dir * radius * 1.12 + bend, dir * radius * 1.32 + bend * 0.2]),
			Color(SEPIA, 0.9), 3.2, true)
	_disc(item, Vector2.ZERO, radius * 1.02, SEPIA.darkened(0.4), INK, 2.4)
	for i in 4:
		item.draw_circle(Vector2.ZERO, radius * (1.0 - i * 0.22), INK.lerp(Color("#2a1f16"), 0.55 - i * 0.12), true, -1.0, true)
	hatch_circle(item, Vector2.ZERO, radius * 0.86, PI / 5.0, 5.0, Color(SEPIA, 0.28), 1.0)
	item.draw_arc(Vector2.ZERO, radius * 0.5, 0.3, TAU * 0.8, 20, Color(SEPIA, 0.5), 1.4, true)
	item.draw_arc(Vector2.ZERO, radius * 0.28, 1.2, TAU * 0.85, 14, Color(SEPIA, 0.4), 1.2, true)
	if lit:
		_glow(item, Vector2.ZERO, radius, GOLD, 1.0)
		item.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, GOLD, 3.0, true)
		item.draw_arc(Vector2.ZERO, radius * 0.6, 0.0, TAU, 28, Color(GOLD, 0.45), 1.6, true)
	else:
		item.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(PAPER, 0.28), 1.4, true)
