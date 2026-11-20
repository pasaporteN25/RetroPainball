@tool
extends Control
## Display de 7 segmentos dibujado a mano: cada segmento es un hexágono.
## Los segmentos apagados se ven tenues, como en un display real, y aparecen
## puntos separadores de miles cuando el número llega a esa cifra.

## Bits por dígito: a=1 b=2 c=4 d=8 e=16 f=32 g=64.
const MASKS := [0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F]

@export_range(1, 12) var digits := 8:
	set(v):
		digits = v
		queue_redraw()
@export var value := 0:
	set(v):
		var next := maxi(0, v)
		if value != next:
			value = next
			queue_redraw()
@export var on_color := Color("#ffb465")
@export var off_alpha := 0.09
## Inclinación tipo itálica de los dígitos.
@export var skew := 0.09


func _draw() -> void:
	var cell := size.x / digits
	var dw := cell * 0.72
	var h := size.y
	var t := dw * 0.2
	var text := str(mini(value, int(pow(10, digits)) - 1))
	var first := digits - text.length()
	for i in digits:
		var mask := 0
		if i >= first:
			mask = MASKS[text.unicode_at(i - first) - 48]
		_draw_digit(Vector2(i * cell + (cell - dw) * 0.5, 0.0), dw, h, t, mask)
		# Separador de miles a la derecha del dígito, si corresponde.
		var from_right := digits - 1 - i
		if from_right > 0 and from_right % 3 == 0:
			var lit := i >= first
			var dot := Vector2(i * cell + cell * 0.5 + dw * 0.5 + (cell - dw) * 0.25, h - t * 0.5)
			dot.x += (h - dot.y) * skew
			if lit:
				draw_circle(dot, t * 0.67, Color(on_color, 0.15), true, -1.0, true)
			draw_circle(dot, t * 0.42, _color(lit), true, -1.0, true)


func _color(lit: bool) -> Color:
	return on_color if lit else Color(on_color, off_alpha)


func _draw_digit(origin: Vector2, w: float, h: float, t: float, mask: int) -> void:
	var half := t * 0.5
	var gap := t * 0.18
	var mid := h * 0.5
	# [inicio, fin] de cada segmento, en orden a..g.
	var segs := [
		[Vector2(half, half), Vector2(w - half, half)],          # a
		[Vector2(w - half, half), Vector2(w - half, mid)],       # b
		[Vector2(w - half, mid), Vector2(w - half, h - half)],   # c
		[Vector2(half, h - half), Vector2(w - half, h - half)],  # d
		[Vector2(half, mid), Vector2(half, h - half)],           # e
		[Vector2(half, half), Vector2(half, mid)],               # f
		[Vector2(half, mid), Vector2(w - half, mid)],            # g
	]
	for s in 7:
		var lit := ((mask >> s) & 1) == 1
		var poly := _segment(origin + segs[s][0], origin + segs[s][1], half, gap, h)
		if lit:
			draw_colored_polygon(_grow(poly, 1.6), Color(on_color, 0.08))
			draw_colored_polygon(_grow(poly, 1.3), Color(on_color, 0.16))
		draw_colored_polygon(poly, _color(lit))
		if lit:
			draw_colored_polygon(_grow(poly, 0.56), on_color.lightened(0.42))


func _segment(a: Vector2, b: Vector2, half: float, gap: float, h: float) -> PackedVector2Array:
	var dir := (b - a).normalized()
	var n := dir.orthogonal()
	var p0 := a + dir * gap
	var p1 := b - dir * gap
	var pts := PackedVector2Array([
		p0,
		p0 + dir * half + n * half,
		p1 - dir * half + n * half,
		p1,
		p1 - dir * half - n * half,
		p0 + dir * half - n * half,
	])
	for i in pts.size():
		pts[i].x += (h - pts[i].y) * skew
	return pts


func _grow(poly: PackedVector2Array, factor: float) -> PackedVector2Array:
	var c := Vector2.ZERO
	for p in poly:
		c += p
	c /= poly.size()
	var out := PackedVector2Array()
	for p in poly:
		out.append(c + (p - c) * factor)
	return out
