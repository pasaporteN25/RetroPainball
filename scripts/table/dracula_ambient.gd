@tool
extends Node2D
## Capa dinámica del arte de Drácula (nubes, murciélagos, ventanas, relámpago, SALVABOLAS).
## La redibuja dracula_art.gd a 20 Hz como máximo; el estado vive allí.

const NIGHT := Color("#0b0a14")
const RED := Color("#9e1b32")
const MOON := Color("#c9d3e6")
const GOLD := Color("#c9a35a")

var art: Node2D


func _draw() -> void:
	if art == null or art._bands.is_empty():
		return
	var lightning := _lightning()
	# Midnight tiñe lentamente el cielo; el relámpago apenas aclara.
	if art._sky_mix > 0.01 or lightning > 0.01:
		var colors: PackedColorArray = art._top_colors
		var tint := Color(RED.darkened(0.3), art._sky_mix * 0.28)
		for i in colors.size():
			colors[i] = Color(tint, tint.a * (1.0 - smoothstep(130.0, 760.0, art._top_field[i].y)))
		draw_polygon(art._top_field, colors)
		if lightning > 0.01:
			draw_colored_polygon(art._top_field, Color(MOON, lightning * 0.05))
	if art._sky_mix > 0.01:
		draw_circle(art.MOON_AT, 46, Color(RED, 0.22 * art._sky_mix), true, -1, true)
	_draw_bolt(lightning)
	_draw_clouds()
	_draw_windows()
	_draw_bats_sky()
	_draw_mist()
	_draw_save_plate()
	if art._jackpot > 0:
		draw_arc(Vector2(336, 830), lerpf(180, 80, art._jackpot), 0, TAU, 48, Color(GOLD, art._jackpot * 0.22), 3, true)


func _lightning() -> float:
	# Un relámpago cada ~22 s con subida y bajada suaves (sin parpadeos).
	var t := fmod(art._time + 14.0, 22.0)
	var e := clampf(1.0 - absf(t - 3.0) / 1.1, 0.0, 1.0)
	return e * e * (3.0 - 2.0 * e)


func _draw_bolt(level: float) -> void:
	if level < 0.01:
		return
	var color := Color(MOON, level * 0.4)
	draw_line(Vector2(560, 212), Vector2(546, 246), color, 2.0, true)
	draw_line(Vector2(546, 246), Vector2(558, 250), color, 2.0, true)
	draw_line(Vector2(558, 250), Vector2(536, 292), color, 2.0, true)
	draw_line(Vector2(560, 212), Vector2(546, 246), Color(MOON, level * 0.1), 7.0, true)


func _cloud(y: float, speed: float, phase: float, length: float, thick: float, alpha: float, tint: Color) -> void:
	var half: float = art._arch_half_width(y) - length * 0.5 - 12.0
	var u := fposmod(phase + art._time * speed, 1.0)
	var x: float = art.ARCH_CENTER.x + (u * 2.0 - 1.0) * half
	var env := sin(u * PI)
	var c := Color(tint, alpha * env)
	draw_line(Vector2(x - length * 0.5, y), Vector2(x + length * 0.5, y), c, thick, true)
	draw_circle(Vector2(x - length * 0.5, y), thick * 0.5, c, true, -1, true)
	draw_circle(Vector2(x + length * 0.5, y), thick * 0.5, c, true, -1, true)
	draw_circle(Vector2(x - length * 0.18, y - thick * 0.55), thick * 0.78, c, true, -1, true)
	draw_circle(Vector2(x + length * 0.14, y - thick * 0.45), thick * 0.65, c, true, -1, true)


func _draw_clouds() -> void:
	var storm := Color(0.2, 0.23, 0.36)
	var lit := Color(0.6, 0.66, 0.8)
	_cloud(150, 0.008, 0.30, 110, 12, 0.3, storm)
	_cloud(250, 0.012, 0.35, 140, 18, 0.24, storm)
	_cloud(272, 0.009, 0.85, 120, 14, 0.2, lit)
	_cloud(306, 0.014, 0.50, 160, 12, 0.14, lit)
	_cloud(332, 0.008, 0.20, 190, 14, 0.12, storm)


func _draw_windows() -> void:
	for i in art.WINDOWS.size():
		var w: Rect2 = art.WINDOWS[i]
		var breath := 0.62 + 0.2 * sin(art._time * 0.6 + i * 1.9)
		var glow := Color(GOLD, 0.0)
		if i == 0:
			breath = 0.95 if art._lock_lit else 0.14
		elif i % 3 == 0:
			continue
		glow = Color(GOLD.lerp(Color("#e0504f"), art._sky_mix), breath * (0.55 + 0.45 * art._sky_mix if i != 0 else 1.0))
		draw_rect(w, glow)
		if i == 0 and art._lock_lit:
			draw_circle(w.get_center(), 14, Color(GOLD, 0.12), true, -1, true)
	# Reloj de la torre: se enciende en Medianoche.
	var clock := Vector2(255, 284)
	draw_circle(clock, 8.5, Color("#0b0a14"), true, -1, true)
	draw_arc(clock, 8.5, 0, TAU, 20, Color(GOLD, 0.35 + 0.55 * art._sky_mix), 1.4, true)
	var hand := Color(GOLD, 0.4 + 0.5 * art._sky_mix)
	draw_line(clock, clock + Vector2(0, -6.0), hand, 1.4, true)
	draw_line(clock, clock + Vector2(5.0 * art._sky_mix, -5.0 * (1.0 - art._sky_mix)) + Vector2(0, 0.0), hand, 1.2, true)


func _draw_bats_sky() -> void:
	# Siluetas reutilizan la misma geometría; el aleteo es lento y suave.
	for i in 7:
		var y := 252.0 + (i % 4) * 24.0 + sin(art._time * 0.5 + i * 1.3) * 5.0
		var half: float = art._arch_half_width(y) - 40.0
		var u := fposmod(float(i) * 0.137 + art._time * (0.006 + 0.002 * (i % 3)), 1.0)
		var x: float = art.ARCH_CENTER.x + (u * 2.0 - 1.0) * half
		var s := 0.5 + (i % 3) * 0.12
		var flap := 0.62 + 0.38 * sin(art._time * 3.2 + i * 2.1)
		draw_set_transform(Vector2(x, y), 0, Vector2(s, s * flap))
		draw_colored_polygon(art.BAT, Color(0.02, 0.02, 0.05, 0.78 * sin(u * PI)))
	draw_set_transform(Vector2.ZERO)


func _draw_mist() -> void:
	# Pocas bandas de niebla; evitan la franja del multiplicador.
	for i in 5:
		var y := 395.0 + i * 131.0
		var drift := sin(art._time * 0.12 + i) * 24.0
		draw_line(Vector2(80 + drift, y), Vector2(590 + drift, y), Color(0.35, 0.4, 0.55, 0.04), 20, true)
	var cut := 0.5 + 0.5 * sin(art._time * 0.15)
	draw_line(Vector2(70 + cut * 30, 372), Vector2(440 + cut * 30, 372), Color(0.5, 0.56, 0.72, 0.05), 16, true)


func _draw_save_plate() -> void:
	draw_rect(Rect2(264, 1335, 144, 47), Color("#090a13"))
	draw_rect(Rect2(264, 1335, 144, 47), Color(GOLD, 0.55), false, 2)
	_draw_centered("SALVABOLAS", Vector2(336, 1360), 15, MOON.lerp(Color.WHITE, art._flash * 0.5) if art._save_fraction > 0 else Color("#777a89"), false)
	draw_rect(Rect2(282, 1367, 108, 3), Color("#33313e"))
	draw_rect(Rect2(282, 1367, 108 * art._save_fraction, 3), MOON)
	if art._flash > 0:
		draw_line(Vector2(266, 1338), Vector2(406, 1338), Color(MOON, art._flash * 0.5), 3, true)

func _draw_centered(label: String, at: Vector2, size: int, color: Color, _shadow := false) -> void:
	var width: float = art._font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var start := at - Vector2(width * 0.5, 0)
	draw_string_outline(art._font, start, label, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, NIGHT)
	draw_string(art._font, start, label, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
