extends RefCounted
## Top 10 de puntajes (sin nombres), por clave de récord (U-05).
## La clave es la mesa y, más adelante, una variante (por ejemplo la dificultad): cada
## clave tiene su propio top. Todo es estático: recibe la ruta del archivo en cada llamada,
## así los tests usan un archivo propio y nunca tocan el real.

const MAX_ENTRIES := 10


## Clave de un top. Sin variante es solo la mesa; con variante, "mesa@variante".
static func key(table_id: String, variant := "") -> String:
	return table_id if variant.is_empty() else "%s@%s" % [table_id, variant]


static func load_top(path: String, record_key: String) -> Array[Dictionary]:
	var top: Array[Dictionary] = []
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return top
	var raw: Variant = cfg.get_value(_section(record_key), "entries", [])
	if raw is Array:
		for item: Variant in raw:
			if item is Dictionary and item.has("score"):
				# Los archivos viejos traían además "initials": se ignora al leer.
				top.append({"score": int(item["score"])})
	top.sort_custom(_by_score)
	return top.slice(0, MAX_ENTRIES)


## Posición (1 a 10) que lograría `score`, o 0 si no entra. Un empate queda detrás del anterior.
static func rank_for(top: Array[Dictionary], score: int) -> int:
	if score <= 0:
		return 0
	var position := 1
	for entry in top:
		if int(entry["score"]) >= score:
			position += 1
	return position if position <= MAX_ENTRIES else 0


## Inserta el puntaje en `top` (lo modifica) y devuelve la posición, o 0 si no entra.
static func insert(top: Array[Dictionary], score: int) -> int:
	var rank := rank_for(top, score)
	if rank == 0:
		return 0
	top.insert(rank - 1, {"score": score})
	while top.size() > MAX_ENTRIES:
		top.pop_back()
	return rank


## Agrega un puntaje al top guardado en `path`. Devuelve la posición (0 si no entra).
static func add(path: String, record_key: String, score: int) -> int:
	var top := load_top(path, record_key)
	var rank := insert(top, score)
	if rank > 0:
		var stored: Array = []
		for entry in top:
			stored.append(entry)
		var cfg := ConfigFile.new()
		cfg.load(path)
		cfg.set_value(_section(record_key), "entries", stored)
		cfg.save(path)
	return rank


static func _section(record_key: String) -> String:
	return "top/" + record_key


static func _by_score(a: Dictionary, b: Dictionary) -> bool:
	return int(a["score"]) > int(b["score"])
