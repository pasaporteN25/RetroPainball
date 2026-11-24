extends SceneTree
## P-07: el preset de Play arma un AAB firmado con el paquete definitivo, sin claves en el repo
## y sin permisos de más; el de debug comparte paquete y versión.

const PACKAGE := "com.pasaporten25.retropinball"
const APP_NAME := "Retro Pinball"

var failures := 0


func _initialize() -> void:
	var cfg := ConfigFile.new()
	_check(cfg.load("res://export_presets.cfg") == OK, "se puede leer export_presets.cfg")
	var play := _find_preset(cfg, "Android Play (AAB)")
	var debug := _find_preset(cfg, "Android")
	_check(play != "" and debug != "", "existen los presets Android (debug) y Android Play (AAB)")
	if play == "" or debug == "":
		quit(1)
		return
	var o := play + ".options"
	var d := debug + ".options"
	_check(cfg.get_value(o, "gradle_build/use_gradle_build") == true, "Play usa la build de Gradle")
	_check(cfg.get_value(o, "gradle_build/export_format") == 1, "Play exporta AAB (no APK)")
	_check(String(cfg.get_value(play, "export_path", "")).ends_with(".aab"), "la salida de Play es un .aab")
	_check(cfg.get_value(o, "architectures/arm64-v8a") == true, "incluye arm64 (obligatorio en Play)")
	_check(cfg.get_value(o, "package/signed") == true, "el AAB sale firmado")
	for key in ["keystore/release", "keystore/release_user", "keystore/release_password"]:
		_check(String(cfg.get_value(o, key, "")) == "", "%s vacío: la clave llega por variables de entorno" % key)
	for section in [o, d]:
		_check(cfg.get_value(section, "package/unique_name") == PACKAGE, "%s usa el paquete %s" % [section, PACKAGE])
		_check(cfg.get_value(section, "package/name") == APP_NAME, "%s se llama %s" % [section, APP_NAME])
		_check(cfg.get_value(section, "permissions/internet", false) == false, "%s no pide Internet" % section)
	var code: Variant = cfg.get_value(o, "version/code")
	_check(typeof(code) == TYPE_INT and code > 0, "version/code es un entero positivo")
	_check(code == cfg.get_value(d, "version/code") and cfg.get_value(o, "version/name") == cfg.get_value(d, "version/name"),
		"debug y Play tienen la misma versión")
	for preset in [play, debug]:
		var excluded := String(cfg.get_value(preset, "exclude_filter", ""))
		_check(excluded.contains("tests/*") and excluded.contains("tools/*") and excluded.contains("docs/*"),
			"%s deja afuera tests, herramientas y docs" % preset)
	_check(ProjectSettings.get_setting("application/config/name") == APP_NAME, "el proyecto se llama " + APP_NAME)
	_check(FileAccess.file_exists("res://docs/play/.gdignore"), "Godot no importa los gráficos de la ficha de Play")
	print("release_preset: %d fallas" % failures)
	quit(1 if failures else 0)


func _find_preset(cfg: ConfigFile, preset_name: String) -> String:
	for section in cfg.get_sections():
		if not section.ends_with(".options") and cfg.get_value(section, "name", "") == preset_name:
			return section
	return ""


func _check(ok: bool, message: String) -> void:
	print(("OK: " if ok else "FALLÓ: ") + message)
	if not ok:
		failures += 1
