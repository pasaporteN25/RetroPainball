@tool
extends Control
## Display de 7 segmentos con puntos separadores de miles.

## Bits por dígito: a=1 b=2 c=4 d=8 e=16 f=32 g=64.
const MASKS := [0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F]

@export_range(1, 12) var digits := 8:
	set(v):
		digits = v
		_segment_size = Vector2.ZERO
		queue_redraw()
@export var value := 0:
	set(v):
		var next := maxi(0, v)
		if value != next:
			value = next
			queue_redraw()
@export var on_color := Color("#ffb465"):
	set(v):
		on_color = v
		queue_redraw()
@export_range(0.0, 1.0, 0.01) var off_alpha := 0.09:
	set(v):
		off_alpha = v
		queue_redraw()
## Inclinación tipo itálica de los dígitos.
@export var skew := 0.09:
	set(v):
		skew = v
		_segment_size = Vector2.ZERO
		queue_redraw()

var _segment_size := Vector2.ZERO
var _segments: Array[PackedVector2Array] = []
var _outlines: Array[PackedVector2Array] = []
var _cores: Array[PackedVector2Array] = []


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var cell := size.x / digits
	var w := cell * 0.72
	var h := size.y
	var t := w * 0.2
	if size != _segment_size:
		_cache_segments(w, h, t)
	var off := Color(on_color, off_alpha)
	var halo := Color(on_color, 0.11)
	var rim := Color(on_color, 0.29)
	var core := on_color.lightened(0.57)
	var text := str(mini(value, int(pow(10, digits)) - 1))
	var first := digits - text.length()
	for i in digits:
		draw_set_transform(Vector2(i * cell + (cell - w) * 0.5, 0.0))
		var mask: int = MASKS[text.unicode_at(i - first) - 48] if i >= first else 0
		for s in 7:
			if (mask & (1 << s)) == 0:
				draw_colored_polygon(_segments[s], off)
			else:
				draw_polyline(_outlines[s], halo, t * 1.15, true)
				draw_polyline(_outlines[s], rim, t * 0.5, true)
				draw_colored_polygon(_segments[s], on_color)
				draw_colored_polygon(_cores[s], core)

		# Separador de miles a la derecha del dígito, si corresponde.
		var from_right := digits - 1 - i
		if from_right > 0 and from_right % 3 == 0:
			var dot := Vector2(w + (cell - w) * 0.25 + t * 0.5 * skew, h - t * 0.5)
			if i >= first:
				draw_circle(dot, t * 0.90, halo, true, -1.0, true)
				draw_circle(dot, t * 0.57, rim, true, -1.0, true)
				draw_circle(dot, t * 0.42, on_color, true, -1.0, true)
				draw_circle(dot, t * 0.23, core, true, -1.0, true)
			else:
				draw_circle(dot, t * 0.42, off, true, -1.0, true)


func _cache_segments(w: float, h: float, t: float) -> void:
	# Los siete moldes se reutilizan para todos los dígitos, incluso al contar puntos.
	_segment_size = size
	_segments.clear()
	_outlines.clear()
	_cores.clear()
	var half := t * 0.5
	var gap := t * 0.18
	var mid := h * 0.5
	var starts := [Vector2(half, half), Vector2(w - half, half), Vector2(w - half, mid),
		Vector2(half, h - half), Vector2(half, mid), Vector2(half, half), Vector2(half, mid)]
	var ends := [Vector2(w - half, half), Vector2(w - half, mid), Vector2(w - half, h - half),
		Vector2(w - half, h - half), Vector2(half, h - half), Vector2(half, mid), Vector2(w - half, mid)]
	for s in 7:
		var a: Vector2 = starts[s]
		var b: Vector2 = ends[s]
		_segments.append(_segment(a, b, half, gap, h))
		var outline := _segments[s].duplicate()
		outline.append(outline[0])
		_outlines.append(outline)
		_cores.append(_segment(a.lerp(b, 0.08), b.lerp(a, 0.08), half * 0.46, gap, h))


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
