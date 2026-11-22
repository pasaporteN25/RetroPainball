extends SceneTree
## U-07: las opciones se guardan y cargan, y toleran archivo ausente o corrupto.

var failures := 0
var path := "user://test_settings_%d.cfg" % OS.get_process_id()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var s := root.get_node("Settings")
	s.path = path
	_check(not s.load_settings(), "archivo ausente devuelve false")
	_check(s.vibration and s.touch_zone == "media" and s.language == "es" and s.volumes[&"Música"] == 1.0, "ausente = valores por defecto")
	s.set_volume(&"Música", 0.4)
	s.set_vibration(false)
	s.set_touch_zone("baja")
	s.set_language("en")
	s.set_language("xx")
	_check(s.language == "en", "idioma inválido ignorado")
	_check(s.save_settings(), "guarda")
	s.set_volume(&"Música", 1.0)
	s.set_vibration(true)
	s.set_touch_zone("media")
	s.set_language("es")
	_check(s.load_settings(), "carga")
	_check(is_equal_approx(s.volumes[&"Música"], 0.4) and not s.vibration and s.touch_zone == "baja" and s.language == "en", "round trip")
	_check(is_equal_approx(s.zone_top_ratio(), 0.7), "ratio de zona baja")
	# otras secciones sobreviven al guardar
	var config := ConfigFile.new()
	config.load(path)
	config.set_value("tutorial", "first_run_seen", true)
	config.save(path)
	s.save_settings()
	config.load(path)
	_check(config.get_value("tutorial", "first_run_seen", false), "conserva otras secciones")
	# corrupto
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("[[[ basura =")
	f.close()
	_check(not s.load_settings(), "corrupto devuelve false")
	_check(s.vibration and s.touch_zone == "media" and s.language == "es", "corrupto = valores por defecto")
	# valores con tipo equivocado
	f = FileAccess.open(path, FileAccess.WRITE)
	f.store_string("[options]\nvolume_Música=\"alto\"\nvibration=3\ntouch_zone=\"x\"\nvolume_Efectos=9.0\n")
	f.close()
	_check(s.load_settings(), "carga parcial")
	_check(s.volumes[&"Música"] == 1.0 and s.vibration and s.touch_zone == "media" and s.volumes[&"Efectos"] == 1.0, "tipos inválidos ignorados y volumen limitado")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	s.path = "user://test_settings_unused.cfg"
	s.load_settings()
	s.apply()
	quit(1 if failures else 0)


func _check(ok: bool, message: String) -> void:
	print(("OK: " if ok else "FALLÓ: ") + message)
	if not ok:
		failures += 1
