extends Node
## Opciones del jugador (M-01, U-07): buses de audio, volúmenes, vibración,
## altura de las zonas táctiles e idioma. Se guardan en un ConfigFile.

signal changed

const BUS_MUSIC := &"Música"
const BUS_EFFECTS := &"Efectos"
const BUS_VOICES := &"Voces"
const BUSES: Array[StringName] = [BUS_MUSIC, BUS_EFFECTS, BUS_VOICES]
const DEFAULT_PATH := "user://settings.cfg"
const SECTION := "options"
## Proporción de pantalla desde la que empiezan las zonas táctiles.
const ZONE_RATIOS := {"media": 0.5, "baja": 0.7}
const LANGUAGES: Array[String] = ["es", "en"]

## Variable (no const) para que los tests usen un archivo propio.
var path := DEFAULT_PATH
var volumes := {BUS_MUSIC: 1.0, BUS_EFFECTS: 1.0, BUS_VOICES: 1.0}
var vibration := true
var touch_zone := "media"
var language := "es"


func _ready() -> void:
	setup_buses()
	load_settings()
	apply()


## Crea los buses que falten. No depende de un default_bus_layout.tres.
func setup_buses() -> void:
	for bus in BUSES:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var index := AudioServer.get_bus_count() - 1
			AudioServer.set_bus_name(index, bus)
			AudioServer.set_bus_send(index, &"Master")


func set_volume(bus: StringName, value: float) -> void:
	if not volumes.has(bus):
		return
	volumes[bus] = clampf(value, 0.0, 1.0)
	_apply_bus(bus)
	changed.emit()


func set_vibration(value: bool) -> void:
	vibration = value
	changed.emit()


func set_touch_zone(value: String) -> void:
	if ZONE_RATIOS.has(value):
		touch_zone = value
		changed.emit()


func set_language(value: String) -> void:
	if LANGUAGES.has(value):
		language = value
		changed.emit()


func zone_top_ratio() -> float:
	return ZONE_RATIOS[touch_zone]


## Vibra solo si la opción está activa.
func vibrate(milliseconds: int) -> void:
	if vibration:
		Input.vibrate_handheld(milliseconds)


func apply() -> void:
	for bus in BUSES:
		_apply_bus(bus)


func _apply_bus(bus: StringName) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index == -1:
		return
	var linear: float = volumes[bus]
	AudioServer.set_bus_mute(index, linear <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.001)))


## Valores por defecto si el archivo falta o está corrupto; los datos sueltos inválidos se ignoran.
func load_settings() -> bool:
	_reset()
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return false
	for bus in BUSES:
		var value: Variant = config.get_value(SECTION, "volume_" + bus, 1.0)
		if typeof(value) in [TYPE_FLOAT, TYPE_INT]:
			volumes[bus] = clampf(float(value), 0.0, 1.0)
	var vib: Variant = config.get_value(SECTION, "vibration", true)
	if typeof(vib) == TYPE_BOOL:
		vibration = vib
	var zone: Variant = config.get_value(SECTION, "touch_zone", "media")
	if typeof(zone) == TYPE_STRING and ZONE_RATIOS.has(zone):
		touch_zone = zone
	var lang: Variant = config.get_value(SECTION, "language", "es")
	if typeof(lang) == TYPE_STRING and LANGUAGES.has(lang):
		language = lang
	return true


func save_settings() -> bool:
	var config := ConfigFile.new()
	# Conserva otras secciones del archivo (por ejemplo la pista del primer uso).
	config.load(path)
	for bus in BUSES:
		config.set_value(SECTION, "volume_" + bus, volumes[bus])
	config.set_value(SECTION, "vibration", vibration)
	config.set_value(SECTION, "touch_zone", touch_zone)
	config.set_value(SECTION, "language", language)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	return config.save(path) == OK


func _reset() -> void:
	volumes = {BUS_MUSIC: 1.0, BUS_EFFECTS: 1.0, BUS_VOICES: 1.0}
	vibration = true
	touch_zone = "media"
	language = "es"
