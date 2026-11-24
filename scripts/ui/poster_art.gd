class_name PosterArt
extends RefCounted
## Pósters 8 bits del backglass de cada mesa en el selector (U-04).
## Contrato: una grilla fija de GRID celdas; cada celda es un píxel grande.
## Cada mesa tiene su paleta corta (máx. 8 colores) y se reconoce de un vistazo.

const GRID := Vector2i(48, 56)


## Dibuja el póster de la mesa `table_id` dentro de `rect` sobre `canvas` (llamar desde un _draw()).
## Los píxeles se alinean a la celda: cell = rect.size / GRID. `time` anima detalles (parpadeos) en segundos.
static func draw(canvas: CanvasItem, table_id: String, rect: Rect2, time: float = 0.0) -> void:
	# Stub: fondo liso. La rama de los pósters lo reemplaza con el arte real.
	canvas.draw_rect(rect, Color(0.1, 0.1, 0.14), true)


## Helper para pintar una celda de la grilla (x, y) con `color`; `w` y `h` en celdas.
static func cell(canvas: CanvasItem, rect: Rect2, x: int, y: int, color: Color, w: int = 1, h: int = 1) -> void:
	var size := Vector2(rect.size.x / GRID.x, rect.size.y / GRID.y)
	canvas.draw_rect(Rect2(rect.position + Vector2(x, y) * size, Vector2(w, h) * size), color, true)
