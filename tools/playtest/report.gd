extends SceneTree
## Informe del playtesting (F1a): lee los .jsonl de una corrida y escribe un Markdown con una tabla
## por mesa y bot, más un PNG de mapa de calor por cada combinación.
##
## Uso:  godot --headless --path . -s tools/playtest/report.gd -- dir=build/playtest/2026-11-24 \
##           [base=build/playtest/2026-11-20] [out=docs/playtest/2026-11-24.md]
## Con `base=` agrega una tabla que compara contra una corrida anterior (antes/después de un cambio).
## Los .jsonl de una misma mesa y bot (varios procesos en paralelo) se suman como una sola muestra.
##
## Limitación: el mapa de calor es solo la grilla de la bola, sin la imagen de la mesa de fondo
## (en headless no hay render para dibujar la mesa).

const ZONES := ["outlane_izq", "centro", "outlane_der"]
const HEAT_PX := 10


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var dir := _path(_arg("dir", ""))
	if dir.is_empty() or not DirAccess.dir_exists_absolute(dir):
		printerr("Falta dir= o no existe: %s" % dir)
		quit(2)
		return
	var date := dir.get_file()
	var out := _path(_arg("out", "docs/playtest/%s.md" % date))
	var groups := _load(dir)
	if groups.is_empty():
		printerr("No hay .jsonl con datos en %s" % dir)
		quit(2)
		return
	var base_groups := {}
	var base_dir := _arg("base", "")
	if not base_dir.is_empty():
		base_groups = _load(_path(base_dir))
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	var png_dir := out.get_basename()
	DirAccess.make_dir_recursive_absolute(png_dir)
	var lines: Array[String] = []
	lines.append("# Informe de playtesting %s" % date)
	lines.append("")
	lines.append("Generado con `tools/playtest/report.gd` a partir de `%s`. Los niveles son de **habilidad del bot**, no de dificultad del juego." % dir.get_file())
	lines.append("")
	var keys := groups.keys()
	keys.sort()
	lines.append_array(_summary_table(keys, groups))
	if not base_groups.is_empty():
		lines.append_array(_compare_table(keys, groups, base_groups, base_dir.get_file()))
	for key: String in keys:
		var g: Dictionary = groups[key]
		var png := "heat_%s.png" % key.replace("/", "_")
		_save_heat(g, png_dir.path_join(png))
		lines.append_array(_detail(key, g, png_dir.get_file() + "/" + png))
	var file := FileAccess.open(out, FileAccess.WRITE)
	if file == null:
		printerr("No se pudo escribir %s" % out)
		quit(1)
		return
	file.store_string("\n".join(lines) + "\n")
	file.close()
	print("Informe: %s (%d combinaciones)" % [out, keys.size()])
	quit(0)


## Carga todos los .jsonl de una carpeta y los agrupa por "mesa/bot".
func _load(dir: String) -> Dictionary:
	var groups := {}
	for file_name in DirAccess.get_files_at(dir):
		if file_name.get_extension() != "jsonl":
			continue
		var file := FileAccess.open(dir.path_join(file_name), FileAccess.READ)
		if file == null:
			continue
		var balls: Array[Dictionary] = []
		var games: Array[Dictionary] = []
		var summary := {}
		while not file.eof_reached():
			var line := file.get_line()
			if line.is_empty():
				continue
			var row: Variant = JSON.parse_string(line)
			if not row is Dictionary:
				continue
			match row.get("type", ""):
				"ball":
					balls.append(row)
				"game":
					games.append(row)
				"summary":
					summary = row
		if summary.is_empty():
			continue  # corrida cortada a la mitad: sin resumen no se usa
		var key := "%s/%s" % [summary.table, summary.bot]
		if not groups.has(key):
			groups[key] = {"balls": [], "games": [], "heat": [], "messages": {}, "points": {},
					"tilts": 0, "saves": 0, "stuck": 0, "escaped": 0, "max_balls": 0, "cut": 0,
					"game_seconds": 0.0, "wall_seconds": 0.0, "runs": 0, "speed": summary.speed}
		var g: Dictionary = groups[key]
		g.balls.append_array(balls)
		g.games.append_array(games)
		for field in ["tilts", "saves", "stuck", "escaped", "game_seconds", "wall_seconds"]:
			g[field] += summary[field]
		g.max_balls = maxi(g.max_balls, int(summary.max_balls))
		g.cut += 1 if summary.cut else 0
		g.runs += 1
		_merge(g.messages, summary.messages)
		_merge(g.points, summary.points)
		var counts: Array = summary.heat.counts
		if g.heat.is_empty():
			g.heat = counts.duplicate()
			g.heat_w = int(summary.heat.w)
			g.heat_h = int(summary.heat.h)
		else:
			for i in counts.size():
				g.heat[i] += counts[i]
	return groups


func _merge(into: Dictionary, from: Dictionary) -> void:
	for k in from:
		into[k] = int(into.get(k, 0)) + int(from[k])


func _summary_table(keys: Array, groups: Dictionary) -> Array[String]:
	var lines: Array[String] = ["## Resumen", "",
			"| Mesa / bot | Bolas | Partidas | Puntos por bola (media / mediana / p90) | Puntos por partida (media / mediana / máx) | Segundos por bola (media) |",
			"|---|---:|---:|---|---|---:|"]
	for key: String in keys:
		var g: Dictionary = groups[key]
		var ball_points := _column(g.balls, "points")
		var game_scores := _column(g.games, "score")
		var seconds := _column(g.balls, "seconds")
		lines.append("| %s | %d | %d | %s | %s | %.1f |" % [key, g.balls.size(), g.games.size(),
				_stats(ball_points, true), _stats(game_scores, false), _mean(seconds)])
	lines.append("")
	return lines


func _compare_table(keys: Array, groups: Dictionary, base: Dictionary, base_name: String) -> Array[String]:
	var lines: Array[String] = ["## Comparación contra %s" % base_name, "",
			"| Mesa / bot | Puntos por bola (antes → ahora) | Cambio | Segundos por bola (antes → ahora) | Cambio |",
			"|---|---|---:|---|---:|"]
	for key: String in keys:
		if not base.has(key):
			lines.append("| %s | sin datos previos | | | |" % key)
			continue
		var now_points := _mean(_column(groups[key].balls, "points"))
		var old_points := _mean(_column(base[key].balls, "points"))
		var now_secs := _mean(_column(groups[key].balls, "seconds"))
		var old_secs := _mean(_column(base[key].balls, "seconds"))
		lines.append("| %s | %.0f → %.0f | %s | %.1f → %.1f | %s |" % [key, old_points, now_points,
				_delta(old_points, now_points), old_secs, now_secs, _delta(old_secs, now_secs)])
	lines.append("")
	return lines


func _detail(key: String, g: Dictionary, png: String) -> Array[String]:
	var total_balls: int = maxi(1, g.balls.size())
	var lines: Array[String] = ["## %s" % key, ""]
	lines.append("- Bolas: %d en %d partidas (%d proceso(s), velocidad x%s, %.0f s de juego en %.0f s reales)." % [
			g.balls.size(), g.games.size(), g.runs, str(g.speed), g.game_seconds, g.wall_seconds])
	var zone_parts: Array[String] = []
	for zone: String in ZONES:
		var n := 0
		for b: Dictionary in g.balls:
			n += 1 if b.zone == zone else 0
		zone_parts.append("%s %.0f%%" % [zone, 100.0 * n / total_balls])
	lines.append("- Por dónde se pierde: %s." % ", ".join(zone_parts))
	var with_kickback := 0
	for b: Dictionary in g.balls:
		with_kickback += 1 if b.kickback else 0
	lines.append("- Se perdió con kickback listo: %.0f%% de las bolas." % (100.0 * with_kickback / total_balls))
	lines.append("- Bolas salvadas: %d, TILT: %d, bolas trabadas: %d, rescates por escape: %d, máximo de bolas a la vez: %d%s." % [
			g.saves, g.tilts, g.stuck, g.escaped, g.max_balls, ", sesiones cortadas por tope: %d" % g.cut if g.cut > 0 else ""])
	lines.append("")
	lines.append("**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):")
	lines.append("")
	lines.append("| Puntos por golpe | Veces | Aporte al total |")
	lines.append("|---:|---:|---:|")
	var rows: Array = []
	var grand := 0
	for k: String in g.points:
		var total: int = int(k) * int(g.points[k])
		grand += total
		rows.append([k, int(g.points[k]), total])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[2] > b[2])
	for row: Array in rows.slice(0, 8):
		lines.append("| %s | %d | %.1f%% |" % [row[0], row[1], 100.0 * row[2] / maxi(1, grand)])
	lines.append("")
	lines.append("**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):")
	lines.append("")
	var msgs: Array = []
	for k: String in g.messages:
		msgs.append([k, int(g.messages[k])])
	msgs.sort_custom(func(a: Array, b: Array) -> bool: return a[1] > b[1])
	for m: Array in msgs.slice(0, 10):
		lines.append("- `%s`: %.2f por bola" % [m[0], float(m[1]) / total_balls])
	lines.append("")
	lines.append("Mapa de calor (por dónde anda la bola, escala logarítmica):")
	lines.append("")
	lines.append("![mapa de calor %s](%s)" % [key, png])
	lines.append("")
	return lines


func _save_heat(g: Dictionary, path: String) -> void:
	var w: int = g.heat_w
	var h: int = g.heat_h
	var image := Image.create(w * HEAT_PX, h * HEAT_PX, false, Image.FORMAT_RGBA8)
	var top := 1.0
	for c in g.heat:
		top = maxf(top, float(c))
	for y in h:
		for x in w:
			var t := log(1.0 + float(g.heat[y * w + x])) / log(1.0 + top)
			var color := Color(0.04, 0.05, 0.1).lerp(Color(0.1, 0.8, 0.9), clampf(t * 2.0, 0.0, 1.0))
			if t > 0.5:
				color = color.lerp(Color(1.0, 0.85, 0.2), clampf((t - 0.5) * 2.0, 0.0, 1.0))
			image.fill_rect(Rect2i(x * HEAT_PX, y * HEAT_PX, HEAT_PX, HEAT_PX), color)
	image.save_png(path)


# --- Estadística ----------------------------------------------------------------------------

func _column(rows: Array, field: String) -> Array[float]:
	var values: Array[float] = []
	for r: Dictionary in rows:
		values.append(float(r[field]))
	return values


func _mean(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for v in values:
		total += v
	return total / values.size()


func _percentile(values: Array[float], p: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	return sorted[clampi(int(ceil(p * sorted.size())) - 1, 0, sorted.size() - 1)]


func _stats(values: Array[float], with_p90: bool) -> String:
	if values.is_empty():
		return "-"
	if with_p90:
		return "%.0f / %.0f / %.0f" % [_mean(values), _percentile(values, 0.5), _percentile(values, 0.9)]
	return "%.0f / %.0f / %.0f" % [_mean(values), _percentile(values, 0.5), _percentile(values, 1.0)]


func _delta(before: float, after: float) -> String:
	if before <= 0.0:
		return "-"
	return "%+.1f%%" % (100.0 * (after - before) / before)


func _path(p: String) -> String:
	if p.is_empty() or p.is_absolute_path():
		return p
	return ProjectSettings.globalize_path("res://").path_join(p)


func _arg(arg_name: String, fallback: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(arg_name + "="):
			return arg.trim_prefix(arg_name + "=")
	return fallback
