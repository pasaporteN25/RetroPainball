extends RefCounted


static func text_bounds(font: Font, label: String, at: Vector2, size: int,
		padding: float, shadow: float = 0.0) -> Rect2:
	# Medí los glifos que se dibujan, incluidos los acentos y el voladizo de la itálica.
	var line := TextLine.new()
	line.add_string(label, font, size)
	var server := TextServerManager.get_primary_interface()
	var pen := at - Vector2(line.get_size().x * 0.5, 0)
	var bounds := Rect2()
	for glyph in server.shaped_text_get_glyphs(line.get_rid()):
		var font_size := Vector2i(glyph.font_size, 0)
		server.font_render_glyph(glyph.font_rid, font_size, glyph.index)
		var offset := server.font_get_glyph_offset(glyph.font_rid, font_size, glyph.index)
		var extent := server.font_get_glyph_size(glyph.font_rid, font_size, glyph.index)
		for repeat in glyph.repeat:
			if extent.x > 0.0 and extent.y > 0.0:
				var ink := Rect2(pen + glyph.offset + offset, extent)
				bounds = bounds.merge(ink) if bounds.has_area() else ink
			pen.x += glyph.advance
	if bounds.has_area():
		bounds.size.y += shadow
		return bounds.grow(padding)
	return bounds


static func title_fits(art: Node2D, wall: Node2D, bounds: Rect2) -> bool:
	if not bounds.has_area():
		return false
	var shape := wall.get_node("Shape") as CollisionPolygon2D
	var field := wall.transform * shape.transform * shape.polygon
	# El borde interior tiene un trazo de line_width + 14 px, desplazado 3 px hacia el tablero.
	var clearance: float = wall.line_width * 0.5 + 12.0
	var inside := (art.transform * bounds).grow(clearance)
	var corners := PackedVector2Array([inside.position, Vector2(inside.end.x, inside.position.y),
		inside.end, Vector2(inside.position.x, inside.end.y)])
	if not Geometry2D.clip_polygons(corners, field).is_empty():
		return false
	# Con keep_width, el ancho lógico queda fijo y la altura sigue la proporción del teléfono.
	var width: float = ProjectSettings.get_setting("display/window/size/viewport_width")
	var table := art.get_parent() as Node2D
	var canvas_bounds := (table.transform if table else Transform2D.IDENTITY) * art.transform * bounds
	for screen in [Vector2(720, 1280), Vector2(1080, 2340), Vector2(1080, 2400)]:
		var visible := Rect2(0, 0, width, width * screen.y / screen.x)
		if not visible.encloses(canvas_bounds):
			return false
	return true
