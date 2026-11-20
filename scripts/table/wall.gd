@tool
extends StaticBody2D
## Pared de la mesa. La forma sale de sus hijos CollisionPolygon2D, que se
## editan con las manijas del editor; este script solo los dibuja.

@export var fill_color := Color(0.16, 0.18, 0.24)
@export var line_color := Color(0.55, 0.6, 0.75)
@export var filled := true
@export var line_width := 4.0
@export var bounce := 0.25


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var mat := PhysicsMaterial.new()
	mat.bounce = bounce
	mat.friction = 0.2
	physics_material_override = mat


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	for child in get_children():
		var shape := child as CollisionPolygon2D
		if shape == null or shape.polygon.size() < 3:
			continue
		var poly := PackedVector2Array()
		for p in shape.polygon:
			poly.append(shape.position + p)
		if filled:
			draw_colored_polygon(poly, fill_color)
		var closed := poly.duplicate()
		closed.append(poly[0])
		draw_polyline(closed, line_color, line_width, true)
