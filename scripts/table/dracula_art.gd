@tool
extends Node2D
## Arte original de Drácula: paisaje impreso y efectos ambientales suaves.

const NIGHT := Color("#0b0a14")
const BLUE := Color("#1b2140")
const RED := Color("#9e1b32")
const MOON := Color("#c9d3e6")
const GOLD := Color("#c9a35a")
var BAT := PackedVector2Array([Vector2(-12, -3), Vector2(-8, -6), Vector2(-3, -3), Vector2(-2, -6), Vector2(0, -4), Vector2(2, -6), Vector2(3, -3), Vector2(8, -6), Vector2(12, -3), Vector2(8, 3), Vector2(5, 1), Vector2(3, 4), Vector2(0, 2), Vector2(-3, 4), Vector2(-5, 1), Vector2(-8, 3)])
var CASTLE := PackedVector2Array([Vector2(170, 360), Vector2(170, 315), Vector2(187, 315), Vector2(187, 274), Vector2(202, 251), Vector2(217, 274), Vector2(217, 305), Vector2(245, 305), Vector2(245, 281), Vector2(257, 281), Vector2(257, 263), Vector2(269, 263), Vector2(269, 281), Vector2(281, 281), Vector2(281, 249), Vector2(304, 216), Vector2(327, 249), Vector2(327, 285), Vector2(354, 285), Vector2(354, 300), Vector2(383, 300), Vector2(383, 267), Vector2(398, 243), Vector2(413, 267), Vector2(413, 314), Vector2(440, 314), Vector2(440, 293), Vector2(454, 293), Vector2(454, 360)])
var _font: SystemFont
var _save_fraction := 0.0
var _flash := 0.0
var _jackpot := 0.0
var _time := 0.0
var _redraw_elapsed := 0.0
var _midnight := false
var _lock_lit := false
var _sky_mix := 0.0


func _ready() -> void:
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Noto Serif", "DejaVu Serif", "serif"])
	_font.font_weight = 700
	var rules := get_node_or_null("../DraculaRules")
	if rules:
		if rules.has_signal("midnight_started"):
			rules.connect("midnight_started", _on_midnight_started)
		if rules.has_signal("midnight_ended"):
			rules.connect("midnight_ended", _on_midnight_ended)
		if rules.has_signal("lock_lit_changed"):
			rules.connect("lock_lit_changed", _on_lock_lit_changed)
		# Leer el estado inicial también permite incorporar el arte con reglas ya activas.
		for property in rules.get_property_list():
			if property.name == "midnight":
				_midnight = bool(rules.get("midnight"))
			elif property.name == "locks_lit":
				_lock_lit = bool(rules.get("locks_lit"))
	set_process(not Engine.is_editor_hint())


func pulse_score() -> void:
	_flash = 1.0
	queue_redraw()


func flash_jackpot() -> void:
	_jackpot = 1.0
	queue_redraw()


func set_ball_save_fraction(fraction: float) -> void:
	_save_fraction = clampf(fraction, 0.0, 1.0)
	queue_redraw()


func _on_midnight_started() -> void:
	_midnight = true


func _on_midnight_ended() -> void:
	_midnight = false


func _on_lock_lit_changed(lit: bool) -> void:
	_lock_lit = lit
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	_flash = move_toward(_flash, 0.0, delta * 2.0)
	_jackpot = move_toward(_jackpot, 0.0, delta * 0.6)
	_sky_mix = move_toward(_sky_mix, 1.0 if _midnight else 0.0, delta * 0.3)
	_redraw_elapsed += delta
	if _redraw_elapsed >= 1.0 / 20.0:
		_redraw_elapsed = 0.0
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 720, 2000), NIGHT)
	# Bandas de degradé impresas, sin texturas ni shaders.
	for i in 32:
		var t := float(i) / 31.0
		var sky := BLUE.lerp(NIGHT, t).lerp(RED.darkened(0.72), _sky_mix * (1.0 - t) * 0.7)
		draw_rect(Rect2(16, 126 + i * 42, 640, 43), sky)
	# Halo lunar y luna llena.
	for i in 4:
		draw_circle(Vector2(336, 235), 74 - i * 7, Color(MOON, 0.025), true, -1, true)
	draw_circle(Vector2(336, 235), 45, Color(MOON, 0.85), true, -1, true)
	draw_circle(Vector2(324, 224), 10, Color(BLUE, 0.09), true, -1, true)
	draw_circle(Vector2(351, 246), 7, Color(BLUE, 0.08), true, -1, true)
	# Nubes en las márgenes superiores; relámpago aislado y de bajo contraste.
	for i in 7:
		var x := 44.0 + i * 92.0
		draw_ellipse_band(Vector2(x, 175 + (i % 2) * 22), 76, Color(0.25, 0.29, 0.41, 0.12))
	var lightning := maxf(0.0, 1.0 - absf(fmod(_time, 18.0) - 12.5) / 1.2)
	draw_line(Vector2(532, 174), Vector2(510, 208), Color(MOON, lightning * 0.15), 2, true)
	draw_line(Vector2(510, 208), Vector2(526, 212), Color(MOON, lightning * 0.15), 2, true)
	draw_line(Vector2(526, 212), Vector2(501, 248), Color(MOON, lightning * 0.15), 2, true)
	draw_colored_polygon(CASTLE, Color("#10101d"))
	draw_polyline(CASTLE, Color(MOON, 0.18), 1.5, true)
	draw_rect(Rect2(300, 245, 8, 15), Color(GOLD, 0.9 if _lock_lit else 0.14))
	if _midnight or _sky_mix > 0.01:
		draw_circle(Vector2(304, 278), 10, Color(GOLD, 0.5 * _sky_mix), false, 1.5, true)
		draw_line(Vector2(304, 278), Vector2(304, 271), Color(GOLD, _sky_mix * 0.6), 1.5, true)
		draw_line(Vector2(304, 278), Vector2(309, 280), Color(GOLD, _sky_mix * 0.6), 1.5, true)
	# Ocho siluetas reutilizan la misma geometría y recorren solo el cielo.
	for i in 8:
		var x := 60.0 + fposmod(float(i) * 91.0 + _time * (3.0 + i % 3), 550.0)
		var y := 337.0 + (i % 3) * 12.0 + sin(_time * 0.5 + i) * 4.0
		draw_set_transform(Vector2(x, y), 0, Vector2.ONE * (0.45 + (i % 2) * 0.15))
		draw_colored_polygon(BAT, Color(0.03, 0.03, 0.07, 0.65))
	draw_set_transform(Vector2.ZERO)
	# Niebla tenue y marcas de piso: no compiten con las piezas ni las lámparas.
	for i in 5:
		var y := 475.0 + i * 133.0
		var drift := sin(_time * 0.12 + i) * 22.0
		draw_line(Vector2(55 + drift, y), Vector2(615 + drift, y), Color(0.35, 0.4, 0.55, 0.045), 13, true)
	for i in 4:
		draw_line(Vector2(65, 930 + i * 43), Vector2(607, 930 + i * 43), Color(MOON, 0.035), 1, true)
	_draw_centered("DRÁCULA", Vector2(336, 155), 34, Color("#e9e1cf"))
	_draw_centered("NOCHE EN TRANSILVANIA", Vector2(336, 175), 13, Color(GOLD, 0.8))
	# Carril de saque y delantal.
	draw_rect(Rect2(663, 443, 44, 985), Color("#151321"))
	draw_line(Vector2(672, 449), Vector2(672, 1390), Color(GOLD, 0.6), 2, true)
	draw_line(Vector2(700, 449), Vector2(700, 1390), Color(MOON, 0.25), 2, true)
	for y in range(487, 1268, 44):
		draw_line(Vector2(678, y + 5), Vector2(686, y - 2), Color(GOLD, 0.45), 1.5, true)
		draw_line(Vector2(686, y - 2), Vector2(694, y + 5), Color(GOLD, 0.45), 1.5, true)
	draw_rect(Rect2(16, 1320, 640, 118), Color("#15121d"))
	draw_line(Vector2(16, 1438), Vector2(707, 1438), Color(GOLD, 0.5), 2)
	draw_rect(Rect2(264, 1335, 144, 47), Color("#090a13"))
	draw_rect(Rect2(264, 1335, 144, 47), Color(GOLD, 0.55), false, 2)
	_draw_centered("SALVABOLAS", Vector2(336, 1360), 15, MOON.lerp(Color.WHITE, _flash * 0.5) if _save_fraction > 0 else Color("#777a89"))
	draw_rect(Rect2(282, 1367, 108, 3), Color("#33313e"))
	draw_rect(Rect2(282, 1367, 108 * _save_fraction, 3), MOON)
	if _flash > 0:
		draw_line(Vector2(266, 1338), Vector2(406, 1338), Color(MOON, _flash * 0.5), 3, true)
	if _jackpot > 0:
		draw_arc(Vector2(336, 830), lerpf(180, 80, _jackpot), 0, TAU, 48, Color(GOLD, _jackpot * 0.22), 3, true)


func draw_ellipse_band(center: Vector2, width: float, color: Color) -> void:
	draw_line(center - Vector2(width * 0.5, 0), center + Vector2(width * 0.5, 0), color, 16, true)


func _draw_centered(label: String, at: Vector2, size: int, color: Color) -> void:
	var width := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string_outline(_font, at - Vector2(width * 0.5, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, NIGHT)
	draw_string(_font, at - Vector2(width * 0.5, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
