@tool
extends Node2D
## Printed playfield and cabinet backing for the Kernel Panic table.

const INK := Color("#070c14")
const AMBER := Color("#f6ad5d")
const MINT := Color("#69e4bc")
const STEEL := Color("#637984")
const TRACE := Color("#2a6c68")
const BURNT_ORANGE := Color("#954637")

var _light: GradientTexture2D
var _grid: ImageTexture
var _title_font: FontVariation
var _save_insert: Node2D
var _save_fraction := 0.0
var _save_lit: StyleBoxFlat
var _save_unlit: StyleBoxFlat
var _circuit_insert: Node2D
var _circuit_routes: Array[Curve2D] = []
var _circuit_time := 0.0
var _circuit_heat := 0.0
var _redraw_time := 0.0


func _ready() -> void:
	var falloff := Gradient.new()
	falloff.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0.28), Color(1, 1, 1, 0)])
	falloff.offsets = PackedFloat32Array([0.0, 0.46, 1.0])
	_light = GradientTexture2D.new()
	_light.width = 192
	_light.height = 192
	_light.gradient = falloff
	_light.fill = GradientTexture2D.FILL_RADIAL
	_light.fill_from = Vector2(0.5, 0.5)
	_light.fill_to = Vector2(1.0, 0.5)

	var grid_image := Image.create_empty(24, 24, false, Image.FORMAT_RGBA8)
	grid_image.fill(Color(0.48, 0.81, 0.75, 0.0))
	for y in range(1, 4):
		for x in range(1, 4):
			var alpha := 0.24 - 0.1 * Vector2(x - 2, y - 2).length()
			grid_image.set_pixel(x, y, Color(0.48, 0.81, 0.75, alpha))
	_grid = ImageTexture.create_from_image(grid_image)
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

	_title_font = FontVariation.new()
	_title_font.base_font = ThemeDB.fallback_font
	_title_font.variation_embolden = 1.2
	_title_font.variation_transform = Transform2D(Vector2(0.98, 0), Vector2(-0.14, 1), Vector2.ZERO)

	_save_insert = Node2D.new()
	_save_insert.name = "BallSaveInsert"
	_save_insert.draw.connect(_draw_save_insert)
	add_child(_save_insert)
	_save_lit = _save_panel(Color("#142c2c"), MINT)
	_save_unlit = _save_panel(Color("#0d1d23"), Color("#668986"))

	_circuit_insert = Node2D.new()
	_circuit_insert.name = "CircuitActivity"
	_circuit_insert.draw.connect(_draw_circuit_activity)
	add_child(_circuit_insert)
	for side in [-1, 1]:
		var route := Curve2D.new()
		for point in [Vector2(258, 835), Vector2(251, 825), Vector2(204, 825),
				Vector2(185, 844), Vector2(185, 900), Vector2(149, 936)]:
			var x: float = point.x if side < 0 else 672.0 - point.x
			route.add_point(Vector2(x, point.y))
		_circuit_routes.append(route)
	# In the editor the traces stay lit without starting a gameplay animation.
	set_process(not Engine.is_editor_hint())


func _process(delta: float) -> void:
	_circuit_time += delta
	_circuit_heat = move_toward(_circuit_heat, 0.0, delta * 1.8)
	_redraw_time += delta
	if _redraw_time >= 1.0 / 30.0:
		_redraw_time = fmod(_redraw_time, 1.0 / 30.0)
		_circuit_insert.queue_redraw()


func pulse_score() -> void:
	_circuit_heat = 1.0
	_circuit_insert.queue_redraw()


func set_ball_save_fraction(fraction: float) -> void:
	var next := clampf(fraction, 0.0, 1.0)
	if next == _save_fraction:
		return
	_save_fraction = next
	_save_insert.queue_redraw()


func _draw() -> void:
	_draw_cabinet()
	_draw_circuit_board()
	_draw_marquee()
	_draw_shooter_lane()
	_draw_apron()


func _draw_cabinet() -> void:
	draw_rect(Rect2(0, 0, 720, 2000), Color("#080c13"))
	_glow(Vector2(360, 128), Vector2(810, 450), Color(0.33, 0.41, 0.48, 0.24))
	var laminate := PackedVector2Array()
	for y in range(10, 1800, 5):
		laminate.append(Vector2(0, y))
		laminate.append(Vector2(720, y))
	draw_multiline(laminate, Color(1.0, 1.0, 1.0, 0.022))
	draw_rect(Rect2(0, 115, 11, 1400), Color("#171e27"))
	draw_rect(Rect2(709, 115, 11, 1400), Color("#171e27"))
	draw_line(Vector2(8, 116), Vector2(8, 1450), Color("#43525d"), 1.0)
	draw_line(Vector2(713, 116), Vector2(713, 1450), Color("#43525d"), 1.0)
	for x in [5, 715]:
		for y in [142, 452, 780, 1120, 1428]:
			_rivet(Vector2(x, y), 3.4)

	var outline := _field_outline()
	draw_colored_polygon(outline, Color("#0e2029"))
	_glow(Vector2(350, 349), Vector2(595, 470), Color(0.1, 0.6, 0.52, 0.19))
	_glow(Vector2(338, 780), Vector2(644, 895), Color(0.16, 0.44, 0.53, 0.23))
	_glow(Vector2(336, 1240), Vector2(625, 450), Color(0.23, 0.075, 0.038, 0.24))


func _field_outline() -> PackedVector2Array:
	var shape := get_node_or_null("../OuterWall/Shape") as CollisionPolygon2D
	if shape:
		return shape.polygon
	return PackedVector2Array([Vector2(16, 472), Vector2(362, 126),
		Vector2(708, 472), Vector2(708, 1800), Vector2(16, 1800)])


func _draw_circuit_board() -> void:
	# Silk-screen dots and parallel copper traces sit under the hardware.
	draw_texture_rect(_grid, Rect2(32, 462, 624, 936), true)

	_trace_pair([Vector2(36, 518), Vector2(70, 484), Vector2(219, 484),
		Vector2(256, 447), Vector2(302, 447)], TRACE, 2.0)
	_trace_pair([Vector2(37, 548), Vector2(89, 496), Vector2(210, 496)], TRACE, 1.5)
	_trace_pair([Vector2(74, 624), Vector2(110, 588), Vector2(177, 588)], TRACE, 2.0)
	_trace_pair([Vector2(47, 660), Vector2(47, 622), Vector2(103, 566), Vector2(159, 566)], TRACE, 2.0)
	_trace_pair([Vector2(64, 700), Vector2(119, 645), Vector2(242, 645),
		Vector2(268, 619)], Color("#80543a"), 2.0)
	_trace_pair([Vector2(56, 740), Vector2(139, 657), Vector2(231, 657),
		Vector2(245, 671), Vector2(284, 671)], TRACE, 2.0)
	_trace_pair([Vector2(92, 756), Vector2(171, 677), Vector2(214, 677),
		Vector2(237, 700), Vector2(278, 700)], TRACE, 1.5)
	_trace_pair([Vector2(80, 854), Vector2(112, 822), Vector2(112, 760),
		Vector2(152, 720), Vector2(274, 720)], TRACE, 2.0)
	_trace_pair([Vector2(127, 853), Vector2(127, 773), Vector2(155, 745),
		Vector2(255, 745), Vector2(287, 777)], Color("#756044"), 2.0)
	_trace_pair([Vector2(22, 917), Vector2(103, 917), Vector2(153, 867),
		Vector2(153, 798), Vector2(187, 764), Vector2(247, 764)], TRACE, 2.0)
	_trace_pair([Vector2(169, 825), Vector2(196, 798), Vector2(247, 798),
		Vector2(266, 817)], TRACE, 2.0)
	_trace_pair([Vector2(149, 936), Vector2(185, 900), Vector2(185, 844),
		Vector2(204, 825), Vector2(247, 825)], TRACE, 2.0)
	_trace_pair([Vector2(156, 962), Vector2(210, 908), Vector2(210, 853),
		Vector2(247, 853)], TRACE, 2.0)
	_trace_pair([Vector2(196, 988), Vector2(272, 912), Vector2(272, 884)], TRACE, 2.0)
	_trace_pair([Vector2(165, 965), Vector2(255, 965), Vector2(289, 931),
		Vector2(289, 892)], Color("#895843"), 2.0)
	_trace_pair([Vector2(224, 1014), Vector2(252, 986), Vector2(283, 986),
		Vector2(307, 962), Vector2(307, 923)], TRACE, 2.0)
	_trace_pair([Vector2(221, 1108), Vector2(270, 1059), Vector2(314, 1059)], TRACE, 2.0)
	_trace_pair([Vector2(242, 1108), Vector2(277, 1073), Vector2(320, 1073)], TRACE, 1.5)
	_trace_pair([Vector2(220, 1191), Vector2(278, 1133), Vector2(315, 1133)], TRACE, 2.0)
	_trace_pair([Vector2(244, 1203), Vector2(284, 1163), Vector2(321, 1163)], Color("#865441"), 2.0)

	for center in [Vector2(185, 532), Vector2(487, 532), Vector2(94, 672),
			Vector2(578, 672), Vector2(220, 934), Vector2(452, 934)]:
		_resistor(center)
	_draw_cpu()
	for y in [972, 1141, 1180]:
		var inset := 5.0 if y == 972 else 0.0
		_chevron(Vector2(336, y), 12.0 + inset, Color(0.36, 0.76, 0.66, 0.44), false)

	# Copper-filled directional graphics under the inlanes.
	for x in [49.0, 623.0]:
		_glow(Vector2(x, 1059), Vector2(64, 225), Color(0.2, 0.92, 0.65, 0.13))
		for y in range(988, 1130, 31):
			_chevron(Vector2(x, y), 12.0, Color(0.43, 0.86, 0.69, 0.58), false)


func _draw_marquee() -> void:
	var center := Vector2(362, 232)
	_glow(center, Vector2(230, 180), Color(0.23, 0.91, 0.66, 0.28))
	draw_circle(center, 64.0, Color("#0b1820"), true, -1.0, true)
	draw_circle(center, 63.0, Color("#397370"), false, 2.0, true)
	draw_circle(center, 53.0, Color("#244d4b"), false, 1.0, true)
	for i in range(24):
		var radial := Vector2.from_angle(TAU * i / 24.0)
		var accent := AMBER if i % 6 == 0 else Color("#305859")
		draw_line(center + radial * 64.0, center + radial * 71.0, accent, 1.5, true)
	for side in [-1.0, 1.0]:
		var left := center + Vector2(side * 72.0, 0)
		var elbow := center + Vector2(side * 115.0, 0)
		var endpoint := center + Vector2(side * 145.0, 30)
		draw_polyline(PackedVector2Array([left, elbow, endpoint]), TRACE, 2.0, true)
		_via(endpoint, TRACE)
		draw_line(elbow + Vector2(0, -12), left + Vector2(0, -12), Color("#386660"), 1.0, true)

	# Circuit penguin mascot engraved into the disc.
	var body := PackedVector2Array([Vector2(-46, 25), Vector2(-30, -5), Vector2(-24, -27),
		Vector2(-12, -39), Vector2(14, -39), Vector2(27, -26), Vector2(31, -5),
		Vector2(45, 25), Vector2(25, 20), Vector2(18, 39), Vector2(-19, 39),
		Vector2(-25, 21)])
	_ink_engraving(center, body, Color("#194045"), MINT)
	var belly := PackedVector2Array([Vector2(-20, 31), Vector2(-15, 4), Vector2(-7, -5),
		Vector2(7, -5), Vector2(16, 5), Vector2(21, 31), Vector2(15, 36), Vector2(-14, 36)])
	_ink_engraving(center, belly, Color("#285859"), Color("#72c8b1"))
	_ink_engraving(center, PackedVector2Array([Vector2(-9, -12), Vector2(0, -18),
		Vector2(10, -12), Vector2(0, -6)]), AMBER, AMBER)
	draw_rect(Rect2(center + Vector2(-13, -27), Vector2(5, 6)), MINT)
	draw_rect(Rect2(center + Vector2(9, -27), Vector2(5, 6)), MINT)
	draw_line(center + Vector2(-24, 43), center + Vector2(-7, 43), AMBER, 3.0, true)
	draw_line(center + Vector2(7, 43), center + Vector2(24, 43), AMBER, 3.0, true)

	var type_center := 360.0
	_title("KERNEL", type_center - 134.0, 372.0, 68, Color("#dff6ed"))
	_title("PANIC", type_center + 131.0, 372.0, 68, AMBER)
	var edge := PackedVector2Array([Vector2(100, 389), Vector2(191, 389), Vector2(208, 406),
		Vector2(509, 406), Vector2(526, 389), Vector2(620, 389)])
	draw_polyline(edge, Color("#325f5e"), 2.0, true)
	draw_line(Vector2(211, 406), Vector2(506, 406), Color("#509886"), 2.0, true)
	draw_rect(Rect2(347, 402, 26, 8), Color("#83d5b7"))
	for x in [102, 619]:
		_via(Vector2(x, 389), Color("#509886"))


func _draw_cpu() -> void:
	var core := Vector2(336, 856)
	var width := 130.0
	var casing := Rect2(core - Vector2(width * 0.5, 37), Vector2(width, 74))
	_glow(core, Vector2(298, 234), Color(0.32, 0.8, 0.66, 0.13))
	draw_rect(casing.grow(5.0), Color("#09141c"))
	draw_rect(casing.grow(5.0), Color("#416060"), false, 1.0)
	draw_rect(casing, Color("#122932"))
	draw_rect(casing.grow(-6.0), Color("#244247"), false, 1.0)
	for i in range(9):
		var x := casing.position.x + 13 + i * 13
		for y in [casing.position.y - 10, casing.end.y]:
			draw_rect(Rect2(x, y, 3, 10), Color("#8a754d"))
			draw_line(Vector2(x, y + 1), Vector2(x + 2, y + 1), Color("#e3ba7c"), 1.0)
	for i in range(4):
		var y := casing.position.y + 16 + i * 14
		draw_rect(Rect2(casing.position.x - 13, y, 13, 3), TRACE.lightened(0.15))
		draw_rect(Rect2(casing.end.x, y, 13, 3), TRACE.lightened(0.15))
	var screen := Rect2(core - Vector2(48, 22), Vector2(96, 44))
	draw_rect(screen, Color("#0a1b22"))
	draw_rect(screen.grow(2), Color("#334b4e"), false, 1)
	for y in range(842, 875, 8):
		draw_line(Vector2(290, y), Vector2(383, y), Color("#163038"))
	for c in [casing.position + Vector2(7, 7), casing.end - Vector2(7, 7)]:
		_rivet(c, 2.0)


func _draw_circuit_activity() -> void:
	var tint := MINT.lerp(AMBER, _circuit_heat * 0.85)
	var pulse := PackedVector2Array()
	var phase := _circuit_time * 1.2 + _circuit_heat * 0.3
	var amplitude := 9.0 + _circuit_heat * 9.0
	for x in range(290, 385, 2):
		var waveform := sin((x - 290) * 0.22 - phase * TAU)
		var envelope := pow(0.5 + 0.5 * sin((x - 290) * 0.123 - phase * TAU), 2.0)
		pulse.append(Vector2(x, 856.0 + waveform * envelope * amplitude))
	_circuit_insert.draw_polyline(pulse, Color(tint, 0.18 + _circuit_heat * 0.35), 6.0, true)
	_circuit_insert.draw_polyline(pulse, Color(tint, 0.72 + _circuit_heat * 0.27), 1.5, true)
	if _circuit_heat <= 0.0 or is_equal_approx(_circuit_heat, 1.0):
		return
	for route in _circuit_routes:
		var head := route.get_baked_length() * (1.0 - _circuit_heat)
		var tail := maxf(0.0, head - 31.0)
		var packet := PackedVector2Array()
		for i in range(8):
			packet.append(route.sample_baked(lerpf(tail, head, i / 7.0)))
		_circuit_insert.draw_polyline(packet, Color(tint, _circuit_heat * 0.35), 10.0, true)
		_circuit_insert.draw_polyline(packet, Color(tint, _circuit_heat), 2.5, true)
		_circuit_insert.draw_circle(packet[-1], 3.0, Color(tint, _circuit_heat), true, -1.0, true)


func _draw_shooter_lane() -> void:
	var lane := Rect2(665, 446, 42, 958)
	draw_rect(lane, Color("#0a131b"))
	draw_rect(Rect2(671, 450, 31, 948), Color("#12212a"))
	draw_rect(Rect2(679, 459, 14, 915), Color("#182d36"))
	draw_line(Vector2(673, 451), Vector2(673, 1380), Color("#314951"), 2.0)
	draw_line(Vector2(699, 451), Vector2(699, 1380), Color("#314951"), 2.0)
	for y in range(468, 1210, 52):
		draw_line(Vector2(675, y), Vector2(699, y), Color("#263f48"), 1.0)
		_chevron(Vector2(686, y + 21), 7.0, Color("#547c79"), true)
	for y in [1160, 1186, 1212]:
		_chevron(Vector2(686, y), 9.0, AMBER.darkened(0.18), true)


func _draw_apron() -> void:
	var chute := PackedVector2Array([Vector2(204, 1332), Vector2(257, 1315),
		Vector2(414, 1315), Vector2(469, 1332), Vector2(469, 1448),
		Vector2(204, 1448)])
	draw_colored_polygon(chute, Color("#09131d"))
	draw_line(Vector2(209, 1395), Vector2(464, 1395), Color("#282c33"), 2.0, true)
	draw_line(Vector2(16, 1442), Vector2(708, 1442), Color("#373d47"), 2.0, true)
	var mailbox := Rect2(276, 1385, 120, 28)
	draw_rect(mailbox.grow(2.0), Color("#172932"))
	draw_rect(mailbox, Color("#05090f"))
	for y in range(1390, 1408, 5):
		draw_line(Vector2(281, y), Vector2(391, y), Color("#101a25"), 1.0)
	for side in [-1, 1]:
		var sign: float = side
		var border := PackedVector2Array([Vector2(336 + sign * 133, 1340),
			Vector2(336 + sign * 94, 1327), Vector2(336 + sign * 73, 1327)])
		draw_polyline(border, Color("#654332"), 2.0, true)
		for i in range(5):
			var x := 336.0 + sign * (78 + i * 9)
			draw_line(Vector2(x, 1408), Vector2(x - sign * 7, 1420),
				BURNT_ORANGE.darkened(0.12), 3.0, true)


func _draw_save_insert() -> void:
	var active := _save_fraction > 0.0
	var tint := MINT if active else Color("#668986")
	var rect := Rect2(260, 1331, 152, 43)
	if active:
		_save_insert.draw_texture_rect(_light, Rect2(220, 1310, 232, 84),
			false, Color(0.28, 0.88, 0.64, 0.22))
	_save_insert.draw_style_box(_save_lit if active else _save_unlit, rect)
	var label := "SALVABOLAS"
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	_save_insert.draw_string(font, Vector2(336 - width * 0.5, 1355), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18, tint)
	_save_insert.draw_rect(Rect2(278, 1360, 116, 3), Color("#243936"))
	if active:
		_save_insert.draw_rect(Rect2(278, 1360, 116 * _save_fraction, 3), tint)


func _save_panel(color: Color, tint: Color) -> StyleBoxFlat:
	var panel := StyleBoxFlat.new()
	panel.bg_color = color
	panel.border_color = tint.darkened(0.45)
	panel.set_corner_radius_all(9)
	panel.set_border_width_all(2)
	return panel


func _title(line: String, center: float, y: float, size: int, tint: Color) -> void:
	var width := _title_font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var baseline := Vector2(center - width * 0.5, y)
	draw_string_outline(_title_font, baseline + Vector2(0, 5), line,
		HORIZONTAL_ALIGNMENT_LEFT, -1, size, 10, Color("#081016"))
	draw_string(_title_font, baseline + Vector2(0, 4), line,
		HORIZONTAL_ALIGNMENT_LEFT, -1, size, tint.darkened(0.7))
	draw_string(_title_font, baseline, line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, tint)


func _ink_engraving(origin: Vector2, points: PackedVector2Array, fill: Color, edge: Color) -> void:
	for i in range(points.size()):
		points[i] += origin
	draw_colored_polygon(points, fill)
	points.append(points[0])
	draw_polyline(points, edge, 2.0, true)


func _trace_pair(route: Array[Vector2], color: Color, width: float) -> void:
	var mirrored := PackedVector2Array()
	for point in route:
		mirrored.append(Vector2(672 - point.x, point.y))
	draw_polyline(PackedVector2Array(route), color, width, true)
	draw_polyline(mirrored, color, width, true)
	_via(route[0], color)
	_via(route[-1], color)
	_via(mirrored[0], color)
	_via(mirrored[-1], color)


func _resistor(center: Vector2) -> void:
	draw_line(center - Vector2(17, 0), center + Vector2(17, 0), Color("#526864"), 2.0)
	draw_rect(Rect2(center - Vector2(10, 4), Vector2(20, 8)), Color("#121d28"))
	draw_rect(Rect2(center - Vector2(3, 4), Vector2(2, 8)), Color("#b37452"))
	draw_rect(Rect2(center + Vector2(3, -4), Vector2(2, 8)), Color("#66a28f"))


func _via(at: Vector2, tint: Color) -> void:
	draw_circle(at, 4.0, INK, true, -1.0, true)
	draw_circle(at, 3.1, tint.lightened(0.14), false, 1.2, true)


func _rivet(at: Vector2, radius: float) -> void:
	draw_circle(at + Vector2(0, 1), radius + 1.0, INK, true, -1.0, true)
	draw_circle(at, radius, STEEL.darkened(0.38), true, -1.0, true)
	draw_arc(at, radius - 0.5, PI, TAU * 0.8, 10, STEEL, 1.0, true)
	draw_line(at - Vector2(radius * 0.42, 0), at + Vector2(radius * 0.42, 0), INK, 1.0, true)


func _chevron(center: Vector2, width: float, color: Color, up: bool) -> void:
	var rise := -width * 0.64 if up else width * 0.64
	draw_polyline(PackedVector2Array([center + Vector2(-width, 0),
		center + Vector2(0, rise), center + Vector2(width, 0)]), color, 2.0, true)


func _glow(center: Vector2, extent: Vector2, color: Color) -> void:
	draw_texture_rect(_light, Rect2(center - extent * 0.5, extent), false, color)
