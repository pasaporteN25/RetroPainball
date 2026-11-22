extends RefCounted
## Viñeta original del castillo para el selector (se dibuja una sola vez por redibujado de la tarjeta).

const NIGHT := Color("#0b0a14")
const BLUE := Color("#1b2140")
const MOON := Color("#c9d3e6")
const GOLD := Color("#c9a35a")
const RED := Color("#9e1b32")

static var BAT := PackedVector2Array([Vector2(0, -3), Vector2(1.6, -6.5), Vector2(3.2, -3.2), Vector2(8, -6),
	Vector2(14, -9), Vector2(20, -5), Vector2(22, -1), Vector2(17.5, -1.5), Vector2(15.5, 3), Vector2(11.5, 0.5),
	Vector2(8.5, 5), Vector2(5, 1.5), Vector2(2.5, 6), Vector2(0, 4), Vector2(-2.5, 6), Vector2(-5, 1.5),
	Vector2(-8.5, 5), Vector2(-11.5, 0.5), Vector2(-15.5, 3), Vector2(-17.5, -1.5), Vector2(-22, -1),
	Vector2(-20, -5), Vector2(-14, -9), Vector2(-8, -6), Vector2(-3.2, -3.2), Vector2(-1.6, -6.5)])
static var CASTLE := PackedVector2Array([Vector2(-135, 90), Vector2(-135, 19), Vector2(-115, 19), Vector2(-115, -19),
	Vector2(-99, -43), Vector2(-83, -19), Vector2(-83, 8), Vector2(-58, 8), Vector2(-58, -10), Vector2(-42, -10),
	Vector2(-42, -34), Vector2(-23, -60), Vector2(-4, -34), Vector2(-4, 8), Vector2(28, 8), Vector2(28, 21),
	Vector2(59, 21), Vector2(59, -12), Vector2(75, -36), Vector2(91, -12), Vector2(91, 28), Vector2(119, 28),
	Vector2(119, 90)])


static func draw(card: Control, rect: Rect2) -> void:
	# Cielo en bandas verticales: cenit oscuro, resplandor frío hacia el horizonte.
	var bands := 14
	for i in bands:
		var t := float(i) / float(bands - 1)
		var y0 := rect.position.y + rect.size.y * float(i) / bands
		card.draw_rect(Rect2(rect.position.x, y0, rect.size.x, rect.size.y / bands + 1.0),
			Color("#0e1230").lerp(Color("#2e3a6c"), smoothstep(0.0, 1.0, t)))
	var c := rect.get_center()
	var scale_factor := minf(rect.size.x / 400.0, rect.size.y / 200.0)
	# Estrellas fijas y nubes tenues repartidas por todo el ancho.
	for i in 28:
		var p := rect.position + Vector2(fposmod(i * 97.0 + 31.0, rect.size.x), fposmod(i * 53.0 + 9.0, rect.size.y * 0.55))
		card.draw_circle(p, 1.4 if i % 4 == 0 else 0.9, Color(MOON, 0.5 if i % 4 == 0 else 0.3))
	for i in 3:
		var cp := rect.position + Vector2(rect.size.x * (0.06 + i * 0.3), rect.size.y * (0.22 + (i % 2) * 0.15))
		card.draw_circle(cp + Vector2(2, 0), 11, Color(0.22, 0.26, 0.42, 0.26), true, -1, true)
		card.draw_circle(cp + Vector2(55, 2), 12, Color(0.22, 0.26, 0.42, 0.26), true, -1, true)
		card.draw_circle(cp + Vector2(100, 3), 9, Color(0.22, 0.26, 0.42, 0.26), true, -1, true)
		card.draw_circle(cp + Vector2(30, -9), 17, Color(0.22, 0.26, 0.42, 0.26), true, -1, true)
		card.draw_circle(cp + Vector2(78, -7), 14, Color(0.22, 0.26, 0.42, 0.26), true, -1, true)
	# Luna con halo.
	var moon := c + Vector2(150, -22) * scale_factor
	for i in 6:
		card.draw_circle(moon, (88 - i * 10) * scale_factor, Color(MOON, 0.03 + i * 0.004), true, -1, true)
	card.draw_circle(moon, 40 * scale_factor, Color("#dfe6f2"), true, -1, true)
	card.draw_circle(moon + Vector2(-11, -9) * scale_factor, 8 * scale_factor, Color("#9aa7c2", 0.5), true, -1, true)
	card.draw_circle(moon + Vector2(10, 9) * scale_factor, 11 * scale_factor, Color("#9aa7c2", 0.45), true, -1, true)
	# Castillo sobre su risco, con ventanas encendidas.
	card.draw_set_transform(c + Vector2(-60, 0) * scale_factor, 0, Vector2.ONE * scale_factor)
	var crag := PackedVector2Array([Vector2(-230, 100), Vector2(-190, 62), Vector2(-150, 70), Vector2(-135, 38),
		Vector2(119, 38), Vector2(150, 58), Vector2(190, 66), Vector2(230, 100)])
	card.draw_colored_polygon(crag, Color("#07060d"))
	card.draw_colored_polygon(CASTLE, NIGHT)
	card.draw_polyline(CASTLE, Color(MOON, 0.3), 2, true)
	for x in range(-135, 119, 16):
		if x < -118 or x > 100 or (x > -40 and x < 20):
			continue
		card.draw_rect(Rect2(x, 13, 8, 6), NIGHT)
	for w in [Rect2(-27, -28, 8, 15), Rect2(-110, -4, 6, 10), Rect2(70, -4, 6, 10), Rect2(-8, 26, 6, 9), Rect2(100, 44, 6, 9)]:
		card.draw_rect(w, GOLD)
		card.draw_rect(w.grow(3), Color(GOLD, 0.12))
	card.draw_set_transform(Vector2.ZERO)
	# Niebla en la base.
	for i in 3:
		var y := rect.end.y - 12.0 - i * 15.0
		card.draw_line(Vector2(rect.position.x + 20 + i * 40, y), Vector2(rect.end.x - 40 - i * 60, y), Color(0.5, 0.56, 0.72, 0.07), 16, true)
	# Murciélagos.
	for b in [[Vector2(85, -62), 1.3, 0.55], [Vector2(122, -18), 0.9, 0.9], [Vector2(-170, -50), 0.8, 0.7], [Vector2(40, -78), 0.7, 0.8]]:
		card.draw_set_transform(c + b[0] * scale_factor, 0, Vector2(b[1], b[1] * b[2]) * scale_factor)
		card.draw_colored_polygon(BAT, Color(0.02, 0.02, 0.05, 0.9))
	card.draw_set_transform(Vector2.ZERO)
