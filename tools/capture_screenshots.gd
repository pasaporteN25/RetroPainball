extends SceneTree
## Capturas para la ficha de Play (P-07): título y una jugada de cada mesa.
## Necesita ventana (no headless):
##   godot --path . -s tools/capture_screenshots.gd
## Guarda en docs/play/screenshots/ PNG de 780 × 1560 (Play no acepta lados de más de 2:1,
## así que se agregan franjas laterales del color de fondo). Usa archivos temporales en user://:
## no toca récords, partidas ni opciones reales.

const OUT_DIR := "res://docs/play/screenshots/"
const SIZE := Vector2i(720, 1560)
const STORE_WIDTH := 780
const TABLES := [
	["03_kernel_panic", "res://scenes/main.tscn"],
	["04_nautilus", "res://scenes/nautilus.tscn"],
	["05_dracula", "res://scenes/dracula.tscn"],
	["06_alicia", "res://scenes/alicia.tscn"],
]

var _scratch := "user://capture_%d" % OS.get_process_id()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node("GameState")
	var settings := root.get_node("Settings")
	game.record_path = _scratch.path_join("records.cfg")
	game.save_directory = _scratch
	settings.path = _scratch.path_join("settings.cfg")
	settings.load_settings()
	DisplayServer.window_set_size(SIZE)
	await create_timer(0.5).timeout
	DirAccess.make_dir_recursive_absolute(OUT_DIR)

	change_scene_to_file("res://scenes/title.tscn")
	await scene_changed
	await create_timer(1.6).timeout
	await _capture("01_title")

	for entry: Array in TABLES:
		change_scene_to_file(entry[1])
		await scene_changed
		await create_timer(0.8).timeout
		if not game.playing:
			game.start_game()
		await create_timer(0.4).timeout
		Input.action_press("launch")
		await create_timer(0.9).timeout
		Input.action_release("launch")
		for i in 8:
			var action := "flipper_left" if i % 2 == 0 else "flipper_right"
			Input.action_press(action)
			await create_timer(0.12).timeout
			Input.action_release(action)
			await create_timer(0.18).timeout
		await _capture(entry[0])

	_cleanup()
	quit()


func _capture(file_name: String) -> void:
	await process_frame
	await process_frame
	var shot := root.get_texture().get_image()
	shot.convert(Image.FORMAT_RGB8)
	if shot.get_size() != SIZE:
		shot.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_LANCZOS)
	var store := Image.create(STORE_WIDTH, SIZE.y, false, Image.FORMAT_RGB8)
	store.fill(shot.get_pixel(0, SIZE.y / 2))
	store.blit_rect(shot, Rect2i(Vector2i.ZERO, SIZE), Vector2i((STORE_WIDTH - SIZE.x) / 2, 0))
	var path := OUT_DIR + file_name + ".png"
	print("captura: %s (ventana %s)" % [path, root.get_texture().get_size()])
	store.save_png(path)


func _cleanup() -> void:
	var dir := DirAccess.open(_scratch)
	if dir:
		for file in dir.get_files():
			dir.remove(file)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_scratch))
