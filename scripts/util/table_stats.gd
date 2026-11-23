extends RefCounted
## Estadísticas por mesa (U-09): partidas jugadas, mejor bola y jackpots. Se guardan en el
## mismo archivo que los récords, en la sección "stats/<mesa>". Todo es estático y recibe la
## ruta en cada llamada, así los tests usan un archivo propio y nunca tocan el real.


## Devuelve {"games": int, "best_ball": int, "jackpots": int}; todo en 0 si no hay datos.
static func load_stats(path: String, table_id: String) -> Dictionary:
	var stats := {"games": 0, "best_ball": 0, "jackpots": 0}
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return stats
	for field: String in stats:
		var value: Variant = cfg.get_value(_section(table_id), field, 0)
		if typeof(value) in [TYPE_INT, TYPE_FLOAT]:
			stats[field] = maxi(int(value), 0)
	return stats


## Suma una partida terminada: sus jackpots y la mejor bola (se queda con el máximo).
static func add_game(path: String, table_id: String, best_ball: int, jackpots: int) -> void:
	var stats := load_stats(path, table_id)
	stats["games"] += 1
	stats["jackpots"] += maxi(jackpots, 0)
	stats["best_ball"] = maxi(int(stats["best_ball"]), best_ball)
	var cfg := ConfigFile.new()
	cfg.load(path)
	for field: String in stats:
		cfg.set_value(_section(table_id), field, stats[field])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	cfg.save(path)


static func _section(table_id: String) -> String:
	return "stats/" + table_id
