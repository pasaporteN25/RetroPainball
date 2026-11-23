extends RefCounted
## Terminación de gabinete para las pantallas que acompañan al HUD.

const Screen := preload("res://scripts/util/screen.gd")


static func box(fill: Color, edge: Color, radius: int = 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	return style


static func panel(control: PanelContainer, palette: TableTheme, accent: Color, margin: int) -> void:
	var style := box(palette.panel_ink_color, palette.panel_frame_color.lerp(accent, 0.64), 18)
	style.set_content_margin_all(margin)
	style.content_margin_top = margin + 12
	style.shadow_color = Color(accent, 0.19)
	style.shadow_size = 10
	control.add_theme_stylebox_override("panel", style)
	control.queue_redraw()


static func draw_trim(control: Control, accent: Color) -> void:
	var left := Vector2(27, 18)
	var right := Vector2(control.size.x - 27, 18)
	var midpoint := (left + right) * 0.5
	var light := accent.lightened(0.22)
	control.draw_line(left, right, Color(accent, 0.48), 2.0, true)
	control.draw_line(midpoint - Vector2(52, 0), midpoint + Vector2(52, 0), Color(light, 0.18), 10.0, true)
	control.draw_line(midpoint - Vector2(52, 0), midpoint + Vector2(52, 0), light, 3.0, true)
	for point in [left, right]:
		control.draw_circle(point, 4.0, light, true, -1.0, true)


static func center_in_safe_area(center: Control) -> void:
	var insets := Screen.safe_insets(center.get_viewport())
	center.offset_top = insets.top
	center.offset_bottom = -insets.bottom


static func font(control: Control, palette: TableTheme) -> void:
	if palette.font:
		control.add_theme_font_override("font", palette.font)
	else:
		control.remove_theme_font_override("font")


static func focus_ring(tint: Color, radius: int = 10) -> StyleBoxFlat:
	var ring := box(Color.TRANSPARENT, tint, radius)
	ring.set_border_width_all(3)
	ring.set_expand_margin_all(3)
	return ring


static func button(control: Button, palette: TableTheme, accent: Color, primary: bool = false) -> void:
	var ink := palette.panel_ink_color
	var fill := accent.lightened(0.32) if primary else ink.lerp(accent, 0.09)
	var text_color := fill.lerp(ink, 0.85) if primary else palette.text_color
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		control.add_theme_color_override(state, text_color)
	control.add_theme_stylebox_override("normal", box(fill, ink.lerp(accent, 0.66)))
	control.add_theme_stylebox_override("hover", box(fill.lightened(0.13), accent.lightened(0.26)))
	control.add_theme_stylebox_override("pressed", box(fill.lerp(accent, 0.25), accent.lightened(0.21)))
	control.add_theme_stylebox_override("focus", focus_ring(palette.text_color))
	font(control, palette)


static func pad_accept_pressed(event: InputEvent) -> bool:
	return event is InputEventJoypadButton and event.button_index == JOY_BUTTON_A and event.pressed


static func enable_pad_accept(control: Button) -> void:
	# Godot deja A fuera de ui_accept. Sumalo solo a los botones de estas pantallas.
	control.gui_input.connect(func(event: InputEvent) -> void:
		if pad_accept_pressed(event):
			control.accept_event()
			control.pressed.emit())
