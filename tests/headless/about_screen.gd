extends SceneTree
## F6: la pantalla Acerca de carga, muestra versión, nombre, links, créditos y aviso de Godot, y el atrás vuelve.

const BackNav := preload("res://scripts/util/back_nav.gd")
var About: GDScript
var scratch := "user://test_about_%d" % OS.get_process_id()
var failures := 0
var opened: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	About = load("res://scripts/ui/about_screen.gd")
	var state := root.get_node("GameState")
	var s := root.get_node("Settings")
	state.save_directory = scratch
	state.record_path = scratch.path_join("records.cfg")
	s.path = scratch.path_join("settings.cfg")
	s.load_settings()
	await _standalone()
	await _from_title()
	await _from_options()
	var dir := DirAccess.open(scratch)
	if dir:
		for file in dir.get_files(): dir.remove(file)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch))
	print("about_screen: %d fallas" % failures)
	quit(1 if failures else 0)


func _go(path: String) -> void:
	change_scene_to_file(path)
	await scene_changed
	await process_frame


func _texts(node: Node) -> Array[String]:
	var found: Array[String] = []
	if node is Label or node is Button:
		found.append(node.text)
	for child in node.get_children():
		found.append_array(_texts(child))
	return found


func _standalone() -> void:
	BackNav.about_return = BackNav.SELECT_SCENE
	await _go("res://scenes/about.tscn")
	var about: Node = current_scene
	var version := str(ProjectSettings.get_setting("application/config/version", ""))
	_check(version != "", "project.godot define application/config/version")
	_check(about._version_label.text == "Versión " + version, "la versión visible sale de ProjectSettings")
	var texts := _texts(about)
	_check(texts.has("RETRO PINBALL"), "muestra el nombre del juego")
	_check(texts.has("Hecho por Lucas Felici (pasaporteN25)"), "muestra la autoría")
	_check(not "\n".join(texts).contains("@"), "no muestra ningún mail")
	_check(texts.has("Código bajo GPL-3.0"), "muestra la licencia del juego")
	_check(about._scroll is ScrollContainer and about._scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "el contenido va en un scroll vertical")
	about.opener = func(url: String) -> void: opened.append(url)
	var expected := {"CodigoFuente": About.SOURCE_URL, "ReportarProblema": About.ISSUES_URL, "Privacidad": About.PRIVACY_URL}
	for id: String in expected:
		var button := about.find_child(id, true, false) as Button
		_check(button != null, "existe el botón " + id)
		if button:
			button.pressed.emit()
	_check(opened == [About.SOURCE_URL, About.ISSUES_URL, About.PRIVACY_URL], "los botones abren los links (sin abrir nada real): %s" % [opened])
	_check(About.SOURCE_URL.begins_with("https://github.com/pasaporteN25/RetroPainball") and About.ISSUES_URL.ends_with("/issues"), "las URL son las del repo")
	var entries: Array = About.credits()
	_check(not entries.is_empty(), "credits.json tiene entradas")
	var missing := 0
	for entry: Dictionary in entries:
		if not texts.has(About.credit_line(entry)):
			missing += 1
	_check(missing == 0 and about._credit_lines.size() == entries.size(), "se listan todos los créditos de credits.json")
	_check(not about.godot_notice_visible(), "el aviso de Godot arranca plegado")
	about.toggle_godot_notice()
	_check(about.godot_notice_visible() and about._godot_text.text.contains(Engine.get_license_text().substr(0, 40)), "el aviso de Godot se despliega con su licencia")
	_check(About.godot_notice().contains("COPYRIGHT"), "el aviso incluye el copyright de Godot")
	about.toggle_godot_notice()
	_check(not about.godot_notice_visible(), "el aviso se vuelve a plegar")
	_check(FileAccess.get_file_as_string("res://LICENSE").contains("GNU GENERAL PUBLIC LICENSE"), "existe LICENSE con la GPL")
	_android_back()
	await scene_changed
	_check(current_scene.scene_file_path == BackNav.SELECT_SCENE, "atrás vuelve a la pantalla de origen configurada")
	_check(BackNav.about_return == "", "el destino se consume")


func _from_title() -> void:
	await _go(BackNav.TITLE_SCENE)
	var title: Node = current_scene
	title._about_button.pressed.emit()
	await scene_changed
	await process_frame
	_check(current_scene.scene_file_path == "res://scenes/about.tscn", "título: Acerca de abre la pantalla")
	_key_back()
	await scene_changed
	_check(current_scene.scene_file_path == BackNav.TITLE_SCENE, "título: Esc en Acerca de vuelve al título")


func _from_options() -> void:
	await _go(BackNav.TITLE_SCENE)
	var title: Node = current_scene
	title.open_options()
	await process_frame
	var options: CanvasLayer = title._options
	options._about_button.pressed.emit()
	await process_frame
	_check(options.about_open() and options._shade.visible, "opciones: Acerca de se abre encima")
	_android_back()
	await process_frame
	await process_frame
	_check(not options.about_open() and options.is_open() and current_scene == title, "opciones: atrás cierra Acerca de y deja las opciones")
	options._about_button.pressed.emit()
	await process_frame
	_key_back()
	await process_frame
	await process_frame
	_check(not options.about_open() and options.is_open(), "opciones: Esc cierra Acerca de y deja las opciones")
	_android_back()
	_check(not options.is_open(), "opciones: otro atrás cierra las opciones")


func _android_back() -> void:
	BackNav.reset()
	root.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)


func _key_back() -> void:
	BackNav.reset()
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	root.push_input(event)


func _check(ok: bool, message: String) -> void:
	print(("OK: " if ok else "FALLÓ: ") + message)
	if not ok:
		failures += 1
