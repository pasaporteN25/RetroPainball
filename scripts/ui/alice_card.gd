extends RefCounted
## Tarjeta de Alicia en el selector (A-08 / S-09): jardín nocturno grabado con la madriguera, abanico de naipes,
## hongo, tetera y la sonrisa del gato entre las sombras. Original, en el estilo de Tenniel (dominio público).
## Reusa el dibujo de las piezas (AliceVisuals) para que tarjeta y mesa se vean igual.

const INK := Color("#14110f")
const GARDEN := Color("#12201f")
const PAPER := Color("#ece2c8")
const SEPIA := Color("#6b5436")
const QUEEN := Color("#b3262e")
const TEA := Color("#2f7f86")
const GOLD := Color("#c9a24a")
const LILAC := Color("#7a5fa8")


static func draw(card: Control, rect: Rect2) -> void:
	# Cielo en bandas: verde profundo arriba, resplandor verdoso al horizonte.
	var bands := 14
	for i in bands:
		var t := float(i) / float(bands - 1)
		card.draw_rect(Rect2(rect.position.x, rect.position.y + rect.size.y * float(i) / bands, rect.size.x,
			rect.size.y / bands + 1.0), Color("#0b1413").lerp(Color("#25423c"), smoothstep(0.0, 1.0, t)))
	var c := rect.get_center()
	var k := minf(rect.size.x / 400.0, rect.size.y / 200.0)
	# Rayado de grabado horizontal en el cielo.
	var lines := PackedVector2Array()
	var y := rect.position.y + 3.0
	while y < rect.position.y + rect.size.y * 0.6:
		lines.append(Vector2(rect.position.x, y))
		lines.append(Vector2(rect.end.x, y))
		y += 6.0
	card.draw_multiline(lines, Color(PAPER, 0.05), 1.0, true)
	# Estrellas en cruz fina.
	for i in 22:
		var p := rect.position + Vector2(fposmod(i * 97.0 + 23.0, rect.size.x), fposmod(i * 53.0 + 11.0, rect.size.y * 0.5))
		var arm := 2.6 if i % 4 == 0 else 1.5
		var col := Color(PAPER, 0.5 if i % 4 == 0 else 0.28)
		card.draw_line(p - Vector2(arm, 0), p + Vector2(arm, 0), col, 1.0, true)
		card.draw_line(p - Vector2(0, arm), p + Vector2(0, arm), col, 1.0, true)
	# Luna creciente (disco claro menos un disco de cielo desplazado).
	var moon := c + Vector2(-142, -58) * k
	for i in 4:
		card.draw_circle(moon, (60 - i * 10) * k, Color(PAPER, 0.025 + i * 0.008), true, -1.0, true)
	card.draw_circle(moon, 24 * k, Color(PAPER, 0.92), true, -1.0, true)
	card.draw_circle(moon + Vector2(10, -4) * k, 21 * k, Color("#14231f"), true, -1.0, true)
	# Seto de fondo con rosas.
	for i in 12:
		var hp := Vector2(rect.position.x + rect.size.x * (i + 0.5) / 12.0, rect.end.y - 40.0 * k + sin(i * 1.7) * 6.0 * k)
		card.draw_circle(hp, 26 * k, Color("#0a1312"), true, -1.0, true)
		card.draw_arc(hp, 26 * k, PI * 1.05, PI * 1.95, 14, Color(PAPER, 0.08), 1.0, true)
		if i % 3 == 1:
			card.draw_circle(hp + Vector2(4, -14) * k, 3.4 * k, Color(QUEEN, 0.7), true, -1.0, true)
	# Suelo con baldosas de ajedrez en perspectiva suave.
	card.draw_rect(Rect2(rect.position.x, rect.end.y - 26.0 * k, rect.size.x, 26.0 * k), Color("#0a1110"))
	for col in 16:
		if col % 2 == 0:
			card.draw_rect(Rect2(rect.position.x + col * rect.size.x / 16.0, rect.end.y - 26.0 * k,
				rect.size.x / 16.0, 26.0 * k), Color(PAPER, 0.045))
	card.draw_line(Vector2(rect.position.x, rect.end.y - 26.0 * k), Vector2(rect.end.x, rect.end.y - 26.0 * k), Color(GOLD, 0.3), 1.0)
	# Madriguera al centro, con las raíces del árbol.
	_piece(card, c + Vector2(-10, 56) * k, k * 1.0, func(): AliceVisuals.draw_rabbithole(card, 34.0, true))
	# Abanico de naipes saliendo de la madriguera (4 palos).
	for i in 4:
		var angle := deg_to_rad(-48.0 + i * 32.0)
		var base := c + Vector2(-10, 20) * k
		var pos := base + Vector2(sin(angle), -cos(angle) * 0.5) * 70.0 * k + Vector2(0, -34.0 * k)
		card.draw_set_transform(pos, angle * 0.7, Vector2.ONE * k)
		AliceVisuals.draw_card(card, i, i % 2 == 0, Vector2(40, 58))
	# Hongo grande a la izquierda y tetera a la derecha.
	_piece(card, c + Vector2(-150, 56) * k, k, func(): AliceVisuals.draw_mushroom(card, 34.0, 0.0))
	_piece(card, c + Vector2(112, 52) * k, k, func(): AliceVisuals.draw_teapot(card, 46.0, true))
	# La sonrisa de Cheshire, flotando entre las sombras (casi todo el gato desvanecido).
	_piece(card, c + Vector2(150, -52) * k, k, func(): AliceVisuals.draw_cheshire(card, 26.0, 0.25))
	card.draw_set_transform(Vector2.ZERO)
	# Filete interior dorado y esquinas.
	card.draw_rect(rect.grow(-5.0), Color(GOLD, 0.35), false, 1.0)
	for corner in [rect.position + Vector2(10, 10), Vector2(rect.end.x - 10, rect.position.y + 10),
			Vector2(rect.position.x + 10, rect.end.y - 10), rect.end - Vector2(10, 10)]:
		card.draw_colored_polygon(PackedVector2Array([corner + Vector2(0, -4), corner + Vector2(4, 0),
			corner + Vector2(0, 4), corner + Vector2(-4, 0)]), Color(QUEEN, 0.85))


## Dibuja una pieza centrada en `at` con escala uniforme.
static func _piece(card: Control, at: Vector2, scale_factor: float, painter: Callable) -> void:
	card.draw_set_transform(at, 0.0, Vector2.ONE * scale_factor)
	painter.call()
	card.draw_set_transform(Vector2.ZERO)
