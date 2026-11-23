extends SceneTree
## M-04: playlist con orden aleatorio sin repetir seguido, crossfade, señal y seguridad sin música.

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _tone(seconds: float) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var data := PackedByteArray()
	data.resize(int(22050 * seconds) * 2)
	wav.data = data
	return wav


func _run() -> void:
	var music := root.get_node("Music")
	var heard: Array = []
	music.track_changed.connect(func(info: Dictionary) -> void: heard.append(info))

	# Sin música: silencio y sin errores.
	music.play_list([])
	_check(not music.is_playing() and heard.is_empty(), "lista vacía = silencio")
	music.play_table("kernel_panic")
	_check(not music.is_playing(), "la mesa sin playlist queda en silencio")
	music.next_track()
	music.stop()
	_check(TableTheme.new().playlist.is_empty(), "TableTheme.playlist vacía por defecto")
	_check(music.bus_name() == &"Música", "usa el bus Música")

	# Orden: nunca repite el anterior seguido.
	music.rng.seed = 7
	var repeats := 0
	var last := -1
	var seen := {}
	for i in 300:
		var index: int = music.pick_index(3, last)
		seen[index] = true
		if index == last:
			repeats += 1
		last = index
	_check(repeats == 0 and seen.size() == 3, "pick_index no repite seguido y usa todos")
	_check(music.pick_index(1, 0) == 0, "con un solo tema lo repite")

	# Reproducción y crossfade.
	music.crossfade_time = 0.3
	music.play_list(["res://no_existe.ogg"])
	_check(not music.is_playing(), "una lista de solo rutas inexistentes queda en silencio")
	heard.clear()
	music.play_list([_tone(5.0), {"stream": _tone(5.0), "title": "Prueba", "author": "Yo", "license": "original"}, _tone(5.0)])
	_check(music.is_playing(), "arranca con streams generados")
	_check(heard.size() == 1, "emite track_changed al arrancar")
	_check(heard[0].has("title") and heard[0].has("index"), "la info trae título e índice")
	var first: AudioStreamPlayer = music.active_player()
	await create_timer(0.5).timeout
	_check(is_equal_approx(first.volume_db, 0.0), "el tema entrante sube a volumen pleno")
	for i in 10:
		music.next_track()
		_check(heard[-1]["index"] != heard[-2]["index"], "no repite el tema anterior seguido (%d)" % i)
	_check(heard.size() == 11, "una señal por tema")
	_check(not heard.any(func(h): return h["path"] == "res://no_existe.ogg"), "ignora rutas inexistentes")
	# Crossfade: al cambiar el entrante arranca bajo y al final queda uno solo.
	var outgoing: AudioStreamPlayer = music.active_player()
	music.next_track()
	var incoming: AudioStreamPlayer = music.active_player()
	_check(incoming != outgoing, "alterna entre los dos players")
	_check(incoming.volume_db < 0.0, "el entrante arranca bajo")
	await create_timer(0.6).timeout
	_check(is_equal_approx(incoming.volume_db, 0.0) and not outgoing.playing, "terminado el crossfade solo suena uno")

	# Stop.
	var stops := [0]
	music.stopped.connect(func() -> void: stops[0] += 1)
	music.stop()
	await create_timer(0.8).timeout
	_check(not music.is_playing() and stops[0] == 1, "stop deja silencio y avisa")
	_check(not music.players()[0].playing and not music.players()[1].playing, "stop apaga los players")
	music.stop()
	_check(stops[0] == 1, "stop repetido no avisa de nuevo")
	quit(1 if failures else 0)


func _check(ok: bool, message: String) -> void:
	print(("OK: " if ok else "FALLÓ: ") + message)
	if not ok:
		failures += 1
