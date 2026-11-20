@tool
extends Node2D
## Serigrafía de los carriles que rodean el núcleo.

const BUS_LEFT := Color("#69ead3")
const BUS_RIGHT := Color("#ffba79")
const BOOT := Color("#98bfed")


func _draw() -> void:
	_draw_lane(PackedVector2Array([Vector2(336, 426), Vector2(336, 495), Vector2(336, 543)]), 68, BOOT)
	var west := PackedVector2Array([
		Vector2(67, 555), Vector2(75, 607), Vector2(83, 660),
		Vector2(95, 704), Vector2(124, 749), Vector2(154, 778),
	])
	var east := PackedVector2Array()
	for point in west:
		east.append(Vector2(672 - point.x, point.y))
	_draw_lane(west, 59, BUS_LEFT)
	_draw_lane(east, 59, BUS_RIGHT)
	_draw_shot_markers()


func _draw_lane(line: PackedVector2Array, width: float, color: Color) -> void:
	draw_polyline(line, Color("#0a1a22"), width + 10.0, true)
	draw_polyline(line, Color(color, 0.48), width + 2.0, true)
	draw_polyline(line, Color("#153039"), width - 2.0, true)
	draw_polyline(line, Color(color, 0.19), width - 11.0, true)
	draw_polyline(line, Color("#0e2730"), width - 14.0, true)
	draw_polyline(line, Color(color, 0.22), 1.5, true)
	for i in range(1, line.size()):
		var start := line[i - 1]
		var end := line[i]
		var direction := start.direction_to(end)
		var normal := direction.orthogonal()
		if start.distance_to(end) >= 48.0:
			var center := start.lerp(end, 0.36)
			draw_polyline(PackedVector2Array([
				center - direction * 3.0 + normal * 7.0,
				center + direction * 4.0,
				center - direction * 3.0 - normal * 7.0,
			]), Color(color, 0.75), 2.2, true)


func _draw_shot_markers() -> void:
	for side in [-1.0, 1.0]:
		var color := BUS_LEFT if side < 0.0 else BUS_RIGHT
		var at := Vector2(336 + side * 115.0, 911)
		var vector := Vector2(side * 10.0, -36)
		var arrow := at + vector
		draw_line(at, arrow, Color(color, 0.55), 2.0, true)
		draw_polyline(PackedVector2Array([
			arrow + Vector2(-5, 9), arrow, arrow + Vector2(8, 5)
		]), Color(color, 0.78), 2.0, true)
