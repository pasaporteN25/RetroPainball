class_name AliceVisuals
extends RefCounted
## Dibujo de las piezas de la mesa Alicia. STUB: lo reemplaza el agente de arte (ver docs/mesas/ALICIA.md).
## Lo llaman desde el `_draw()` de cada pieza (scripts/table/alice_*.gd, las escribe lógica). Todo se dibuja
## centrado en el origen local de `item`. Mantener estas firmas: son el contrato entre lógica y arte.

const SUIT_SPADES := 0
const SUIT_HEARTS := 1
const SUIT_DIAMONDS := 2
const SUIT_CLUBS := 3
const SIZE_DRINK := 0
const SIZE_EAT := 1


## Naipe del banco. `flipped` = ya dado vuelta (encendido). `size` = tamaño del blanco en px.
static func draw_card(item: CanvasItem, _suit: int, flipped: bool, size: Vector2) -> void:
	item.draw_rect(Rect2(-size / 2.0, size), Color("#ece2c8") if flipped else Color("#6b5436"))


## Blanco BEBÉ-ME (SIZE_DRINK) o CÓMEME (SIZE_EAT). `active` = es el tamaño actual.
static func draw_size_target(item: CanvasItem, kind: int, active: bool, radius: float) -> void:
	var color := Color("#2f7f86") if kind == SIZE_DRINK else Color("#b3262e")
	item.draw_circle(Vector2.ZERO, radius, color if active else color.darkened(0.5))


## Gato de Cheshire. `visibility` 0..1: 1 = visible (golpeable), 0 = solo queda la sonrisa tenue.
static func draw_cheshire(item: CanvasItem, radius: float, visibility: float) -> void:
	item.draw_circle(Vector2.ZERO, radius, Color(0.48, 0.37, 0.66, 0.2 + 0.8 * visibility))


## Hongo (bumper). `flash` 0..1 = destello al golpe.
static func draw_mushroom(item: CanvasItem, radius: float, flash: float) -> void:
	item.draw_circle(Vector2.ZERO, radius, Color("#b3262e").lerp(Color.WHITE, flash))


## Tetera (jackpot de Té Loco). `lit` = Té Loco activo.
static func draw_teapot(item: CanvasItem, radius: float, lit: bool) -> void:
	item.draw_circle(Vector2.ZERO, radius, Color("#c9a24a") if lit else Color("#6b5436"))


## Madriguera (plato). `lit` = LOCK encendido.
static func draw_rabbithole(item: CanvasItem, radius: float, lit: bool) -> void:
	item.draw_circle(Vector2.ZERO, radius, Color("#14110f"))
	if lit:
		item.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color("#c9a24a"), 3.0)
