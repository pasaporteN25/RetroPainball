@tool
extends StaticBody2D
## El perfil de cada rail se dibuja a partir de su polígono de colisión.

@export var fill_color := Color("#212d38")
@export var line_color := Color("#889da1")
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
		var profile := PackedVector2Array()
		for point in shape.polygon:
			profile.append(shape.transform * point)
		if shape.build_mode == CollisionPolygon2D.BUILD_SEGMENTS:
			_draw_cabinet_rim(profile)
		else:
			_draw_hardware(profile)


func _draw_cabinet_rim(profile: PackedVector2Array) -> void:
	# The cabinet arch follows the outer segments, leaving the field artwork visible.
	var inner := PackedVector2Array()
	for point in profile:
		var toward_center := Vector2(362, maxf(472.0, point.y)) - point
		inner.append(point + toward_center.normalized() * 3.0)
	draw_polyline(inner, Color("#060a10"), line_width + 14.0, true)
	draw_polyline(profile, fill_color, line_width + 8.0, true)
	draw_polyline(profile, Color("#55636c"), line_width, true)
	draw_polyline(inner, Color("#97704d"), 2.0, true)
	var chrome := PackedVector2Array()
	for point in inner:
		chrome.append(point - Vector2(0, 2))
	draw_polyline(chrome, line_color.darkened(0.08), 1.0, true)


func _draw_hardware(profile: PackedVector2Array) -> void:
	var rim := profile.duplicate()
	rim.append(profile[0])
	draw_polyline(rim, Color("#070c13"), line_width + 7.0, true)
	if filled:
		var finish := PackedColorArray()
		for vertex in profile:
			var reflection := cos(vertex.y * 0.005 + absf(vertex.x - 336.0) * 0.01)
			finish.append(fill_color.lerp(Color("#62747e"), (reflection + 1.0) * 0.13))
		draw_polygon(profile, finish)
	draw_polyline(rim, Color("#465a61"), line_width, true)
	draw_polyline(rim, line_color, 1.0, true)
	if not filled:
		return

	var bounds := Rect2(profile[0], Vector2.ZERO)
	for point in profile:
		bounds = bounds.expand(point)
	if bounds.size.x < 16.0:
		return

	# The fasteners follow the wall body and stay away from its lit edges.
	var x := bounds.get_center().x
	for y in range(int(bounds.position.y) + 24, mini(int(bounds.end.y) - 12, 1440), 89):
		var at := Vector2(x, y)
		if (Geometry2D.is_point_in_polygon(at - Vector2(12, 0), profile)
				and Geometry2D.is_point_in_polygon(at + Vector2(12, 0), profile)):
			_draw_bolt(at)

	if bounds.size.y < 250.0:
		return
	var stripe_x := bounds.position.x + 15 if x < 336.0 else bounds.end.x - 15
	for y in range(int(bounds.position.y) + 63, 1420, 30):
		var at := Vector2(stripe_x, y)
		if (Geometry2D.is_point_in_polygon(at - Vector2(8, 0), profile)
				and Geometry2D.is_point_in_polygon(at + Vector2(8, 0), profile)):
			draw_line(at + Vector2(-6, 7), at + Vector2(6, -7), Color("#415b5c"), 3.0, true)


func _draw_bolt(at: Vector2) -> void:
	draw_circle(at + Vector2(0, 1), 5.8, Color("#080d14"), true, -1.0, true)
	draw_circle(at, 4.5, Color("#576a71"), true, -1.0, true)
	draw_arc(at, 4.0, PI, TAU * 0.8, 12, Color("#9ca9a5"), 1.0, true)
	draw_line(at - Vector2(2, 1), at + Vector2(2, 1), Color("#131b25"), 1.0, true)
