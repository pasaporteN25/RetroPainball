extends SceneTree
## S-01: cada mesa tiene un TableTheme válido y HUD, pausa, popups, récords y selector lo leen.

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, detail: String) -> void:
	if not condition:
		failures += 1
		printerr("FALLÓ: " + detail)

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_directory = ""
	state.record_path = "user://test_table_theme_%d_records.cfg" % OS.get_process_id()
	# Valores que hoy salen del código: el aspecto no puede cambiar.
	var ids := ["kernel_panic", "nautilus", "dracula"]
	var names := {"kernel_panic": "Kernel Panic", "nautilus": "20.000 Leguas", "dracula": "Drácula"}
	var menu := {"kernel_panic": Color("#75e6c6"), "nautilus": Color("#ffbc6b"), "dracula": Color("#75e6c6")}
	var select := {"kernel_panic": Color("#8cead2"), "nautilus": Color("#ffd397"), "dracula": Color("#c0314d")}
	for id: String in ids:
		check(ResourceLoader.exists("res://resources/themes/%s.tres" % id), "existe el .tres de " + id)
		var theme: TableTheme = state.active_theme(id)
		check(theme != null and theme.table_id == id, "tema válido para " + id)
		check(theme.display_name == names[id], "nombre de " + id)
		check(theme.menu_accent == menu[id] and theme.select_accent == select[id], "acentos de " + id)
		check(not theme.popup_font_names.is_empty() and theme.mode_names != null, "popup y modos de " + id)
	check(state.active_theme("no_existe").table_id == "kernel_panic", "mesa desconocida cae a Kernel Panic")
	var kernel: TableTheme = state.active_theme("kernel_panic")
	check(kernel.popup_color == Color("#83ff91") and kernel.popup_plate_color == Color("#071b0d"), "popup de Kernel")
	var nautilus: TableTheme = state.active_theme("nautilus")
	check(nautilus.popup_color == Color("#78e4db") and nautilus.popup_border_color == Color("#c5a15b"), "popup de Nautilus")
	check(kernel.display_color == Color("#ffb465") and kernel.score_label_color == Color("#ffbc6b"), "HUD de Kernel")
	state.table_id = "nautilus"
	check(state.active_theme() == nautilus, "active_theme() sigue a table_id")

	# El HUD toma el color del display y de las etiquetas desde el tema.
	state.table_id = "kernel_panic"
	var hud = load("res://scripts/ui/hud.gd").new()
	root.add_child(hud)
	check(hud._t == kernel, "el HUD lee el tema de la mesa activa")
	check(hud._display.on_color == kernel.display_color, "el display usa display_color del tema")
	hud.free()
	var tinted: TableTheme = nautilus.duplicate()
	tinted.display_color = Color("#123456")
	check(tinted.display_color != nautilus.display_color, "el tema es editable por mesa")
	state.table_id = "nautilus"
	var hud2 = load("res://scripts/ui/hud.gd").new()
	root.add_child(hud2)
	check(hud2._t == nautilus, "el HUD de Nautilus lee el tema de Nautilus")
	hud2.free()

	var popup = load("res://scripts/fx/score_popup.gd").new()
	popup.setup(100, Vector2(300, 300), Color.WHITE)
	check(popup.color == nautilus.popup_color and popup.border_color == nautilus.popup_border_color, "el popup lee el tema activo")
	popup.free()

	var pause = load("res://scripts/ui/pause_menu.gd").new()
	root.add_child(pause)
	pause.set_paused(true)
	check(pause._accent == nautilus.menu_accent, "la pausa toma el acento del tema")
	state.table_id = "dracula"
	pause.set_paused(true)
	check(pause._accent == state.active_theme("dracula").menu_accent, "la pausa cambia de acento con la mesa")
	pause.free()

	var records = load("res://scripts/ui/records_screen.gd").new()
	root.add_child(records)
	check(records._tables.size() == 3 and records._tables[2][1] == "Drácula" and records._tables[1][2] == Color("#ffbc6b"), "récords lee nombres y acentos del tema")
	records.free()
	print("TableTheme: %d fallos" % failures)
	quit(1 if failures else 0)
