extends SceneTree
## A-09: el preset apunta a los íconos correctos y el logo queda dentro de la máscara de Android.

const ASSET_DIR := "res://assets/branding/"
const OPTIONS := "preset.0.options"

var failures := 0


func _initialize() -> void:
	var preset := ConfigFile.new()
	_check(preset.load("res://export_presets.cfg") == OK, "se puede leer el preset")
	_check(preset.get_value("preset.0", "platform", "") == "Android", "el preset sigue siendo de Android")
	_check(ProjectSettings.get_setting("application/config/icon") == "res://icon.svg", "Godot usa el ícono nuevo")
	_icon(preset, "main_192x192", "res://icon.svg", 192)

	var foreground := _icon(preset, "adaptive_foreground_432x432", ASSET_DIR + "android_foreground.svg", 432)
	var background := _icon(preset, "adaptive_background_432x432", ASSET_DIR + "android_background.svg", 432)
	var monochrome := _icon(preset, "adaptive_monochrome_432x432", ASSET_DIR + "android_monochrome.svg", 432)
	_check(not foreground.is_empty() and foreground.detect_alpha() != Image.ALPHA_NONE,
		"el frente deja ver el fondo")
	_check(not background.is_empty() and background.detect_alpha() == Image.ALPHA_NONE,
		"el fondo cubre toda la capa")
	_check(_has_safe_silhouette(monochrome), "la silueta blanca queda en el círculo seguro de 264 px")

	var splash_path: String = ProjectSettings.get_setting("application/boot_splash/image", "")
	_check(splash_path == ASSET_DIR + "boot_splash.png", "Godot arranca con el PNG del logo")
	_check(ProjectSettings.get_setting("application/boot_splash/show_image"), "el splash está habilitado")
	_check(ProjectSettings.get_setting("application/boot_splash/stretch_mode") == 1, "el splash respeta la proporción")
	var splash := Image.new()
	_check(splash.load_png_from_buffer(FileAccess.get_file_as_bytes(splash_path)) == OK, "el PNG se puede leer")
	_check(splash.get_width() == 720 and splash.get_height() == 1200, "el splash tiene formato vertical")
	if not splash.is_empty():
		var ink: Color = ProjectSettings.get_setting("application/boot_splash/bg_color")
		_check(splash.get_pixel(0, 0).to_html() == ink.to_html(), "el fondo del PNG coincide con el de arranque")
		_check(splash.get_pixel(400, 410).get_luminance() > 0.45, "se dibuja la pelota del logo")
	print("app_branding: %d fallas" % failures)
	quit(1 if failures else 0)


func _icon(preset: ConfigFile, key: String, path: String, size: int) -> Image:
	_check(preset.get_value(OPTIONS, "launcher_icons/" + key, "") == path, "el preset apunta a " + path)
	var icon := Image.new()
	_check(icon.load_svg_from_string(FileAccess.get_file_as_string(path)) == OK, "se puede leer el SVG " + path)
	var square := icon.get_width() == icon.get_height()
	_check(square and icon.get_width() >= size and icon.get_used_rect().has_area(),
		"imagen cuadrada y visible de al menos %d px en %s" % [size, path])
	return icon


func _has_safe_silhouette(image: Image) -> bool:
	if image.is_empty() or image.detect_alpha() == Image.ALPHA_NONE:
		return false
	var painted := 0
	var center := Vector2(image.get_size()) * 0.5
	var radius := image.get_width() * 66.0 / 216.0
	var bounds := image.get_used_rect()
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			var pixel := image.get_pixel(x, y)
			if pixel.a < 0.5:
				continue
			if pixel.get_luminance() < 0.99 or Vector2(x + 0.5, y + 0.5).distance_to(center) > radius:
				return false
			painted += 1
	return painted > 0


func _check(ok: bool, message: String) -> void:
	print(("OK: " if ok else "FALLÓ: ") + message)
	if not ok:
		failures += 1
