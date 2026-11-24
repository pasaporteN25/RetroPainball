extends SceneTree
## F6: pantalla Acerca de. Versión, créditos, avisos de Godot, enlaces, accesos desde Opciones y título,
## y el botón atrás de Android.

var failures := 0
var scratch := "user://test_about_%d" % OS.get_process_id()
var opened: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	var s := root.get_node("Settings")
	state.save_directory = scratch
	state.record_path = scratch.path_join("records.cfg")
	s.path = scratch.path_join("settings.cfg")
	s.load_settings()
	var BackNav := load("res://scripts/util/back_nav.gd")
	var About := load("res://scripts/ui/about_screen.gd")

	var version := str(ProjectSettings.get_setting("application/config/version", ""))
	_check(not version.is_empty(), "project.godot define application/config/version")
	var presets := FileAccess.get_file_as_string("res://export_presets.cfg")
	_check(presets.count('version/name="%s"' % version) == 2, "la versión coincide con los dos presets de exportación")

	change_scene_to_file("res://scenes/title.tscn")
	await scene_changed
	var title := current_scene
	var about = title.get_node("AboutScreen")
	about.open_url = func(url: String) -> void: opened.append(url)
	_check(not about.is_open(), "Acerca de arranca cerrada")
	title._about_button.pressed.emit()
	_check(about.is_open(), "el título abre Acerca de")
	await process_frame
	await process_frame
	_check(about._version_label.text == "Versión " + version, "muestra la versión del proyecto")
	_check(about._author_label.text == About.AUTHOR_NAME, "muestra el nombre de 'Hecho por'")
	_check(root.get_visible_rect().encloses(about._panel.get_global_rect()), "entra en la pantalla")
	_check(about._back.has_focus(), "Volver recibe el foco al abrir")

	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string("res://resources/credits.json"))["entries"]
	var all_text := ""
	for node in about._credits_box.get_children():
		if node is Label:
			all_text += node.text + "\n"
	var missing := 0
	for entry: Dictionary in entries:
		if not all_text.contains(entry.title):
			missing += 1
	_check(entries.size() > 0 and missing == 0, "los %d créditos de credits.json aparecen" % entries.size())

	_check(Engine.get_license_text().length() > 100, "Godot entrega su texto de licencia")
	_check(Engine.get_copyright_info().size() > 0, "Godot entrega los avisos de copyright")
	_check(about._notices_box.get_child_count() == 0 and not about._notices_box.visible, "los avisos de Godot empiezan ocultos")
	about._notices_toggle.pressed.emit()
	var notices := ""
	for node in about._notices_box.get_children():
		notices += (node as Label).text + "\n"
	_check(about._notices_box.visible and notices.contains(Engine.get_license_text().substr(0, 40)), "el botón muestra la licencia de Godot")
	_check(notices.contains(str(Engine.get_copyright_info()[0].name)), "incluye el copyright de las bibliotecas")
	about._notices_toggle.pressed.emit()
	_check(not about._notices_box.visible, "el botón vuelve a ocultar los avisos")

	for caption in ["Códigofuente", "Reportarunproblema", "Políticadeprivacidad"]:
		(about._buttons.filter(func(b: Button) -> bool: return b.name == caption)[0] as Button).pressed.emit()
	_check(opened == [About.SOURCE_URL, About.ISSUES_URL, About.PRIVACY_URL], "los tres botones abren su enlace")
	_check(About.SOURCE_URL == "https://github.com/pasaporteN25/RetroPainball" and About.ISSUES_URL.ends_with("/issues")
		and About.PRIVACY_URL.ends_with("docs/PRIVACY.md"), "los enlaces apuntan al repo")

	title.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_check(not about.is_open() and current_scene == title, "atrás cierra Acerca de sin salir del título")
	_check(not title.exit_armed(), "ese atrás no arma la salida de la app")

	BackNav.reset()
	title.open_options()
	var options = title._options
	var from_options = options.get_node("AboutScreen")
	from_options.open_url = about.open_url
	options._about_button.pressed.emit()
	_check(from_options.is_open() and options.is_open(), "Opciones abre Acerca de")
	options.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_check(not from_options.is_open() and options.is_open(), "atrás cierra solo Acerca de y deja las opciones")
	BackNav.reset()
	options.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_check(not options.is_open(), "un segundo atrás cierra las opciones")

	BackNav.reset()
	title.open_about()
	var event := InputEventAction.new()
	event.action = &"ui_cancel"
	event.pressed = true
	root.push_input(event)
	await process_frame
	_check(not about.is_open() and not title.exit_armed(), "Esc también cierra Acerca de")

	current_scene.free()
	var dir := DirAccess.open(scratch)
	if dir:
		for file in dir.get_files(): dir.remove(file)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch))
	print("about_screen: %d fallas" % failures)
	quit(1 if failures else 0)


func _check(ok: bool, message: String) -> void:
	print(("OK: " if ok else "FALLÓ: ") + message)
	if not ok:
		failures += 1
