extends SceneTree
## M-01: los buses Música / Efectos / Voces existen al arrancar y aplican volúmenes.

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var settings := root.get_node("Settings")
	settings.path = "user://test_audio_%d.cfg" % OS.get_process_id()
	for bus in ["Música", "Efectos", "Voces"]:
		_check(AudioServer.get_bus_index(bus) != -1, "existe el bus " + bus)
	var count := AudioServer.get_bus_count()
	settings.setup_buses()
	_check(AudioServer.get_bus_count() == count, "setup_buses no duplica buses")
	settings.set_volume(&"Música", 0.5)
	var music := AudioServer.get_bus_index("Música")
	_check(is_equal_approx(AudioServer.get_bus_volume_db(music), linear_to_db(0.5)), "aplica volumen 0.5")
	settings.set_volume(&"Efectos", 0.0)
	_check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Efectos")), "volumen 0 silencia el bus")
	settings.set_volume(&"Voces", 7.0)
	_check(settings.volumes[&"Voces"] == 1.0, "el volumen se limita a 1")
	settings.set_volume(&"Master", 0.0)
	_check(not settings.volumes.has(&"Master"), "ignora buses desconocidos")
	settings.set_volume(&"Música", 1.0)
	settings.set_volume(&"Efectos", 1.0)
	quit(1 if failures else 0)


func _check(ok: bool, message: String) -> void:
	print(("OK: " if ok else "FALLÓ: ") + message)
	if not ok:
		failures += 1
