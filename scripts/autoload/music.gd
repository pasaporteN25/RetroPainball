extends Node
## Reproductor de playlist por mesa (M-04). Reproduce por el bus Música de Settings, con orden
## aleatorio que nunca repite el tema anterior seguido y crossfade entre temas usando dos
## AudioStreamPlayer. Lista vacía = silencio, sin errores (hoy no hay música real cargada).
## Cada tema de la lista puede ser un AudioStream, una ruta `res://...` o un Dictionary con
## `stream` o `path` más datos libres (title, author, license). Si la ruta está en
## `resources/credits.json` (Q-06), el aviso toma título, autor y licencia de ahí.
## M-05 se engancha a `track_changed` para mostrar "Sonando: ..."; acá no hay UI.

## Se emite al empezar cada tema. `info`: id, title, author, license, source, path, index.
signal track_changed(info: Dictionary)
## Se emite al quedar sin música (stop).
signal stopped

const CREDITS_PATH := "res://resources/credits.json"
const SILENT_DB := -60.0

## Segundos de superposición entre un tema y el siguiente.
var crossfade_time := 2.0
var rng := RandomNumberGenerator.new()
## Tema que suena ahora (info), vacío si no suena nada.
var current_info := {}

var _items: Array = []
var _last_index := -1
var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _tween: Tween
var _credits := {}
var _credits_loaded := false


func _ready() -> void:
	rng.randomize()
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = bus_name()
		add_child(player)
		_players.append(player)


## Arranca la playlist de la mesa `table_id` (campo `playlist` de su TableTheme).
func play_table(table_id: String) -> void:
	play_list(Array(TableTheme.for_table(table_id).playlist))


## Arranca una lista. Si es vacía corta lo que suene y queda en silencio.
func play_list(items: Array) -> void:
	stop()
	_items = items.duplicate()
	_last_index = -1
	if not _items.is_empty():
		next_track()


## Corta la música (con fundido de salida) y olvida la lista.
func stop() -> void:
	_items = []
	_last_index = -1
	var was_playing := not current_info.is_empty()
	current_info = {}
	if _players.is_empty():
		return
	_kill_tween()
	_tween = create_tween().set_parallel(true)
	for player in _players:
		if player.playing:
			_tween.tween_property(player, "volume_db", SILENT_DB, minf(crossfade_time, 0.5))
	_tween.chain().tween_callback(_stop_players)
	if was_playing:
		stopped.emit()


func is_playing() -> bool:
	return not current_info.is_empty()


## Pasa al siguiente tema (aleatorio, distinto del anterior) con crossfade.
func next_track() -> void:
	if _items.is_empty() or _players.is_empty():
		return
	var index := pick_index(_items.size(), _last_index)
	var stream := _stream_of(_items[index])
	if stream == null:
		# Tema ilegible: se lo saca de la lista para no entrar en un ciclo de errores.
		_items.remove_at(index)
		if index < _last_index:
			_last_index -= 1
		if _items.is_empty():
			current_info = {}
		next_track()
		return
	_last_index = index
	current_info = _info_of(_items[index], index)
	var incoming := _players[1 - _active]
	var outgoing := _players[_active]
	_active = 1 - _active
	_kill_tween()
	incoming.stream = stream
	incoming.volume_db = SILENT_DB
	incoming.play()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(incoming, "volume_db", 0.0, crossfade_time)
	if outgoing.playing:
		_tween.tween_property(outgoing, "volume_db", SILENT_DB, crossfade_time)
		_tween.chain().tween_callback(outgoing.stop)
	track_changed.emit(current_info)


## Índice al azar en [0, count) distinto de `last` (si hay más de uno).
func pick_index(count: int, last: int) -> int:
	if count <= 1:
		return 0
	if last < 0 or last >= count:
		return rng.randi_range(0, count - 1)
	var index := rng.randi_range(0, count - 2)
	return index + 1 if index >= last else index


func bus_name() -> StringName:
	return &"Música" if AudioServer.get_bus_index(&"Música") != -1 else &"Master"


## El jugador que suena ahora (los tests lo miran).
func active_player() -> AudioStreamPlayer:
	return _players[_active] if not _players.is_empty() else null


func players() -> Array[AudioStreamPlayer]:
	return _players


func _process(_delta: float) -> void:
	if current_info.is_empty() or _items.is_empty():
		return
	var player := _players[_active]
	var stream := player.stream
	if stream == null:
		return
	var length := stream.get_length()
	# Pasa al siguiente cuando dejó de sonar o faltan `crossfade_time` segundos para el final.
	if not player.playing or (length > crossfade_time * 2.0 and player.get_playback_position() >= length - crossfade_time):
		next_track()


func _stop_players() -> void:
	for player in _players:
		player.stop()


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()


func _stream_of(item: Variant) -> AudioStream:
	if item is AudioStream:
		return item
	if item is Dictionary:
		if item.get("stream") is AudioStream:
			return item["stream"]
		return _stream_of(str(item.get("path", "")))
	var path := str(item)
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream


func _info_of(item: Variant, index: int) -> Dictionary:
	var info := {"id": "", "title": "", "author": "", "license": "", "source": "", "path": "", "index": index}
	var path := ""
	if item is Dictionary:
		path = str(item.get("path", ""))
		for key in item:
			if key != "stream":
				info[key] = item[key]
	elif item is String or item is StringName:
		path = str(item)
	if not path.is_empty():
		info["path"] = path
		var credit: Dictionary = _credits_by_path().get(path, {})
		for key in ["id", "title", "author", "license", "source"]:
			if str(info[key]).is_empty() and credit.has(key):
				info[key] = credit[key]
	if str(info["title"]).is_empty():
		info["title"] = path.get_file().get_basename() if not path.is_empty() else "Tema %d" % (index + 1)
	return info


func _credits_by_path() -> Dictionary:
	if _credits_loaded:
		return _credits
	_credits_loaded = true
	if not FileAccess.file_exists(CREDITS_PATH):
		return _credits
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(CREDITS_PATH))
	if data is Dictionary:
		for entry in data.get("entries", []):
			if entry is Dictionary and entry.has("path"):
				_credits[str(entry["path"])] = entry
	return _credits
