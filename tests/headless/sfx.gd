extends SceneTree
## M-02: los efectos base se generan en código y se reproducen sin errores (también headless).

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var sfx := root.get_node("Sfx")
	for sound in sfx.NAMES:
		var wav: AudioStreamWAV = sfx.stream_of(sound)
		_check(wav != null and wav.data.size() > 1000, "se generó " + sound)
		if wav:
			var peak := 0
			for i in range(0, wav.data.size() - 1, 2):
				peak = maxi(peak, absi(wav.data.decode_s16(i)))
			_check(peak > 1000 and peak <= 32767, "%s no es silencio ni satura" % sound)
		sfx.play(sound)
		_check(sfx.play_counts.get(sound, 0) == 1, "play(%s) se registra" % sound)
	sfx.play(&"inexistente")
	_check(not sfx.play_counts.has(&"inexistente"), "ignora sonidos desconocidos")
	var bus: StringName = sfx._players[0].bus
	_check(bus == &"Efectos", "sale por el bus Efectos")
	quit(1 if failures else 0)


func _check(ok: bool, message: String) -> void:
	print(("OK: " if ok else "FALLÓ: ") + message)
	if not ok:
		failures += 1
