extends Control
## Pantalla "Acerca de" (F6): versión, autoría, links, créditos, aviso de Godot y licencia del juego.
## Se abre como escena propia (desde el título) o incrustada sobre Opciones (`embedded`), y en los dos
## casos el atrás vuelve a la pantalla de origen.

signal closed

const Arcade := preload("res://scripts/ui/arcade_style.gd")
const BackNav := preload("res://scripts/util/back_nav.gd")
const Screen := preload("res://scripts/util/screen.gd")
const CREDITS_PATH := "res://resources/credits.json"
const SOURCE_URL := "https://github.com/pasaporteN25/RetroPainball"
const ISSUES_URL := "https://github.com/pasaporteN25/RetroPainball/issues"
const PRIVACY_URL := "https://github.com/pasaporteN25/RetroPainball/blob/master/docs/PRIVACY.md"
const AUTHOR := "Lucas Felici (pasaporteN25)"
const LICENSE_LINE := "Código bajo GPL-3.0"
## Orden y nombre de cada grupo de créditos (los `kind` de credits.json).
const KIND_TITLES := {"art": "ARTE Y EFECTOS", "music": "MÚSICA", "font": "TIPOGRAFÍAS"}

## true si está sobre otra pantalla (Opciones): al volver se cierra en vez de cambiar de escena.
var embedded := false
## Cómo se abre un link; los tests lo reemplazan para no abrir nada real.
var opener: Callable = func(url: String) -> void: OS.shell_open(url)

var _palette: TableTheme
var _shade: ColorRect
var _panel: PanelContainer
var _title: Label
var _scroll: ScrollContainer
var _headings: Array[Label] = []
var _texts: Array[Label] = []
var _buttons: Array[Button] = []
var _links := {}
var _credit_lines: Array[String] = []
var _version_label: Label
var _godot_toggle: Button
var _godot_text: Label
var _back: Button


func _ready() -> void:
	_palette = GameState.active_theme()
	_shade = ColorRect.new()
	add_child(_shade)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	_shade.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	_fit_safe_area(margin)
	get_viewport().size_changed.connect(func() -> void: _fit_safe_area(margin))
	_panel = PanelContainer.new()
	_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_panel.custom_minimum_size.x = 648
	margin.add_child(_panel)
	_panel.draw.connect(func() -> void: Arcade.draw_trim(_panel, _palette.menu_accent))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_panel.add_child(column)
	_title = _text("ACERCA DE", 48, HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(_title)
	_scroll = ScrollContainer.new()
	_scroll.name = "Scroll"
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	column.add_child(_scroll)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(content)
	_build_content(content)
	_back = Button.new()
	_back.name = "Volver"
	_back.text = "Volver"
	_back.custom_minimum_size.y = 68
	_back.add_theme_font_size_override("font_size", 27)
	_back.pressed.connect(go_back)
	column.add_child(_back)
	_buttons.append(_back)
	for button in _buttons:
		Arcade.enable_pad_accept(button)
	_apply_theme()
	_back.grab_focus()


static func app_version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", ""))


## Entradas de credits.json (la misma lista que valida tests/headless/credits.gd).
static func credits() -> Array:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(CREDITS_PATH))
	if typeof(data) == TYPE_DICTIONARY and typeof(data.get("entries")) == TYPE_ARRAY:
		return data["entries"]
	return []


## Una línea de crédito: "Título — Autor (licencia)".
static func credit_line(entry: Dictionary) -> String:
	return "%s — %s (%s)" % [entry.get("title", "?"), entry.get("author", "?"), entry.get("license", "?")]


## Aviso de copyright y licencia de Godot Engine y de las bibliotecas que trae.
static func godot_notice() -> String:
	var lines: PackedStringArray = ["Este juego usa Godot Engine (https://godotengine.org).", "", Engine.get_license_text(), "",
		"COPYRIGHT DE GODOT Y SUS BIBLIOTECAS", ""]
	for component: Dictionary in Engine.get_copyright_info():
		lines.append(str(component.get("name", "")))
		for part: Dictionary in component.get("parts", []):
			for copyright in part.get("copyright", []):
				lines.append("  © " + str(copyright))
			lines.append("  Licencia: " + str(part.get("license", "")))
		lines.append("")
	return "\n".join(lines)


func _build_content(content: VBoxContainer) -> void:
	content.add_child(_text("RETRO PINBALL", 38, HORIZONTAL_ALIGNMENT_CENTER, true))
	_version_label = _text("Versión " + app_version(), 24, HORIZONTAL_ALIGNMENT_CENTER)
	_version_label.name = "Version"
	content.add_child(_version_label)
	var author := _text("Hecho por " + AUTHOR, 24, HORIZONTAL_ALIGNMENT_CENTER)
	author.name = "Author"
	content.add_child(author)
	content.add_child(_text(LICENSE_LINE, 20, HORIZONTAL_ALIGNMENT_CENTER))
	content.add_child(_text("ENLACES", 17, HORIZONTAL_ALIGNMENT_LEFT, true))
	_link_button(content, "CodigoFuente", "Código fuente", SOURCE_URL)
	_link_button(content, "ReportarProblema", "Reportar un problema", ISSUES_URL)
	_link_button(content, "Privacidad", "Política de privacidad", PRIVACY_URL)
	var by_kind := {}
	for entry: Dictionary in credits():
		var list: Array = by_kind.get(entry.get("kind", ""), [])
		list.append(entry)
		by_kind[entry.get("kind", "")] = list
	for kind: String in KIND_TITLES:
		if not by_kind.has(kind):
			continue
		content.add_child(_text(KIND_TITLES[kind], 17, HORIZONTAL_ALIGNMENT_LEFT, true))
		for entry: Dictionary in by_kind[kind]:
			var line := credit_line(entry)
			_credit_lines.append(line)
			content.add_child(_text(line, 19, HORIZONTAL_ALIGNMENT_LEFT))
	content.add_child(_text("HECHO CON GODOT ENGINE", 17, HORIZONTAL_ALIGNMENT_LEFT, true))
	_godot_toggle = Button.new()
	_godot_toggle.name = "GodotNotice"
	_godot_toggle.custom_minimum_size.y = 60
	_godot_toggle.add_theme_font_size_override("font_size", 22)
	_godot_toggle.pressed.connect(toggle_godot_notice)
	content.add_child(_godot_toggle)
	_buttons.append(_godot_toggle)
	_godot_text = _text("", 15, HORIZONTAL_ALIGNMENT_LEFT)
	_godot_text.visible = false
	content.add_child(_godot_text)
	_update_toggle()


func _link_button(parent: Control, id: String, caption: String, url: String) -> void:
	var button := Button.new()
	button.name = id
	button.text = caption
	button.custom_minimum_size.y = 60
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(open_url.bind(url))
	parent.add_child(button)
	_buttons.append(button)
	_links[id] = url


## Abre un link con `opener` (OS.shell_open en el juego).
func open_url(url: String) -> void:
	opener.call(url)


func godot_notice_visible() -> bool:
	return _godot_text.visible


## Muestra u oculta el aviso de Godot; el texto largo se arma recién la primera vez.
func toggle_godot_notice() -> void:
	_godot_text.visible = not _godot_text.visible
	if _godot_text.visible and _godot_text.text.is_empty():
		_godot_text.text = godot_notice()
	_update_toggle()


func _update_toggle() -> void:
	_godot_toggle.text = "Aviso de Godot Engine: " + ("ocultar" if _godot_text.visible else "mostrar")


## Atrás (botón, Android, Esc o B): vuelve a la pantalla de origen.
func go_back() -> void:
	if not BackNav.claim():
		return
	if embedded:
		closed.emit()
		queue_free()
	else:
		get_tree().change_scene_to_file.call_deferred(BackNav.take_about_return())


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()


func _unhandled_input(event: InputEvent) -> void:
	if BackNav.is_back_event(event):
		get_viewport().set_input_as_handled()
		go_back()


func _fit_safe_area(margin: MarginContainer) -> void:
	var insets := Screen.safe_insets(get_viewport())
	margin.offset_top = insets.top
	margin.offset_bottom = -insets.bottom


func _text(text: String, size: int, align: HorizontalAlignment, heading := false) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", size)
	if heading:
		_headings.append(label)
	else:
		_texts.append(label)
	return label


func _apply_theme() -> void:
	var accent := _palette.menu_accent
	_shade.color = _palette.backdrop_color
	Arcade.panel(_panel, _palette, accent, 28)
	for label in _texts:
		Arcade.font(label, _palette)
		label.add_theme_color_override("font_color", _palette.text_color)
	for label in _headings:
		Arcade.font(label, _palette)
		label.add_theme_color_override("font_color", accent.lightened(0.32))
	_godot_text.add_theme_color_override("font_color", _palette.muted_color)
	for button in _buttons:
		Arcade.button(button, _palette, accent, button == _back)
