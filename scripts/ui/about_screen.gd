extends CanvasLayer
## Pantalla "Acerca de" (F6): versión, autoría, enlaces, créditos y avisos de Godot.
## Se abre encima de Opciones o del título; cierra con Volver, Esc o el atrás de Android.

signal closed

const BackNav := preload("res://scripts/util/back_nav.gd")
const Arcade := preload("res://scripts/ui/arcade_style.gd")
const Screen := preload("res://scripts/util/screen.gd")
const CREDITS_PATH := "res://resources/credits.json"
const GAME_NAME := "Retro Pinball"
# DECISIÓN PENDIENTE (PLAN_BETA #2): cómo aparece el nombre en "Hecho por" y si va un contacto (sin mail).
const AUTHOR_NAME := "Lucas"
# DECISIÓN PENDIENTE (PLAN_BETA #3): licencia del código (MIT, GPL-3.0 o reservada).
# TODO: cuando Lucas decida, crear LICENSE y mostrar la licencia acá. Hoy no se muestra ninguna.
const SOURCE_URL := "https://github.com/pasaporteN25/RetroPainball"
const ISSUES_URL := SOURCE_URL + "/issues"
const PRIVACY_URL := SOURCE_URL + "/blob/master/docs/PRIVACY.md"
const KIND_HEADINGS := {"art": "ARTE", "font": "TIPOGRAFÍAS", "music": "MÚSICA"}

## Reemplazable en los tests para no abrir el navegador de verdad.
var open_url: Callable = func(url: String) -> void: OS.shell_open(url)

var _shade: ColorRect
var _panel: PanelContainer
var _palette: TableTheme
var _title: Label
var _scroll: ScrollContainer
var _version_label: Label
var _author_label: Label
var _credits_box: VBoxContainer
var _notices_box: VBoxContainer
var _notices_toggle: Button
var _back: Button
var _buttons: Array[Button] = []
var _labels: Array[Label] = []
var _headings: Array[Label] = []
var _notices_built := false


func _ready() -> void:
	layer = 22
	_shade = ColorRect.new()
	add_child(_shade)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	_shade.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Arcade.center_in_safe_area(center)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size.x = 584
	center.add_child(_panel)
	get_viewport().size_changed.connect(_fit)
	_panel.draw.connect(func() -> void: Arcade.draw_trim(_panel, _palette.menu_accent))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_panel.add_child(column)
	_title = _label(column, GAME_NAME.to_upper(), 40, HORIZONTAL_ALIGNMENT_CENTER)
	_version_label = _label(column, "", 22, HORIZONTAL_ALIGNMENT_CENTER)
	_version_label.name = "Version"
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_scroll)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(body)
	_heading(body, "HECHO POR")
	_author_label = _label(body, AUTHOR_NAME, 26)
	_author_label.name = "Author"
	_heading(body, "ENLACES")
	_link_button(body, "Código fuente", SOURCE_URL)
	_link_button(body, "Reportar un problema", ISSUES_URL)
	_link_button(body, "Política de privacidad", PRIVACY_URL)
	_heading(body, "CRÉDITOS")
	_credits_box = VBoxContainer.new()
	_credits_box.name = "Credits"
	_credits_box.add_theme_constant_override("separation", 4)
	body.add_child(_credits_box)
	_build_credits()
	_heading(body, "HECHO CON GODOT ENGINE")
	_notices_toggle = Button.new()
	_notices_toggle.name = "GodotNotices"
	_notices_toggle.custom_minimum_size = Vector2(0, 60)
	_notices_toggle.add_theme_font_size_override("font_size", 22)
	_notices_toggle.pressed.connect(_toggle_notices)
	body.add_child(_notices_toggle)
	_buttons.append(_notices_toggle)
	_notices_box = VBoxContainer.new()
	_notices_box.name = "GodotNoticesBox"
	_notices_box.add_theme_constant_override("separation", 6)
	_notices_box.hide()
	body.add_child(_notices_box)
	_back = Button.new()
	_back.name = "Volver"
	_back.text = "Volver"
	_back.custom_minimum_size = Vector2(0, 72)
	_back.add_theme_font_size_override("font_size", 27)
	_back.pressed.connect(close)
	column.add_child(_back)
	_buttons.append(_back)
	_wire_focus()
	_apply_theme()
	_refresh_notices_text()
	_shade.hide()


## Versión legible (la de application/config/version).
static func version_text() -> String:
	var version := str(ProjectSettings.get_setting("application/config/version", ""))
	return version if not version.is_empty() else "sin versión"


## Entradas de credits.json agrupadas por tipo.
static func load_credits() -> Dictionary:
	var grouped := {}
	var file := FileAccess.open(CREDITS_PATH, FileAccess.READ)
	if file == null:
		return grouped
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or not (parsed as Dictionary).get("entries") is Array:
		return grouped
	for entry: Variant in parsed["entries"]:
		if entry is Dictionary:
			var kind := str(entry.get("kind", ""))
			if not grouped.has(kind):
				grouped[kind] = []
			grouped[kind].append(entry)
	return grouped


func is_open() -> bool:
	return _shade.visible


func open() -> void:
	_apply_theme()
	_fit()
	_shade.show()
	_scroll.scroll_vertical = 0
	_back.grab_focus()


func close() -> void:
	if not _shade.visible:
		return
	_shade.hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if _shade.visible and BackNav.is_back_event(event):
		get_viewport().set_input_as_handled()
		go_back()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()


## Atrás: cierra Acerca de y vuelve a la pantalla anterior.
func go_back() -> void:
	if _shade.visible and BackNav.claim():
		close()


## Abre una URL con el navegador del sistema (en los tests se reemplaza `open_url`).
func open_link(url: String) -> void:
	open_url.call(url)


func _fit() -> void:
	if _panel == null:
		return
	Arcade.center_in_safe_area(_panel.get_parent())
	var insets := Screen.safe_insets(get_viewport())
	var available: float = get_viewport().get_visible_rect().size.y - insets.top - insets.bottom
	_panel.custom_minimum_size.y = maxf(320.0, available - 24.0)


func _label(parent: Control, text: String, font_size: int, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	_labels.append(label)
	return label


func _heading(parent: Control, text: String, font_size := 17) -> void:
	var label := _label(parent, text, font_size)
	_labels.erase(label)
	_headings.append(label)


func _link_button(parent: Control, caption: String, url: String) -> void:
	var button := Button.new()
	button.name = caption.replace(" ", "")
	button.text = caption
	button.custom_minimum_size = Vector2(0, 60)
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(open_link.bind(url))
	parent.add_child(button)
	_buttons.append(button)


func _build_credits() -> void:
	var grouped := load_credits()
	if grouped.is_empty():
		_label(_credits_box, "No se pudo leer la lista de créditos.", 20)
		return
	var kinds: Array = KIND_HEADINGS.keys().filter(func(k: String) -> bool: return grouped.has(k))
	for kind: String in grouped:
		if not kinds.has(kind):
			kinds.append(kind)
	for kind: String in kinds:
		_heading(_credits_box, KIND_HEADINGS.get(kind, kind.to_upper()), 18)
		for entry: Dictionary in grouped[kind]:
			var line := "%s — %s (%s)" % [entry.get("title", "?"), entry.get("author", "?"), entry.get("license", "?")]
			_label(_credits_box, line, 19)


func _toggle_notices() -> void:
	_notices_box.visible = not _notices_box.visible
	_refresh_notices_text()
	if _notices_box.visible:
		_build_notices()


func _refresh_notices_text() -> void:
	_notices_toggle.text = "Ocultar avisos de Godot" if _notices_box.visible else "Ver avisos de Godot"


## Aviso MIT de Godot y copyright de las bibliotecas que trae (lo exige su licencia).
func _build_notices() -> void:
	if _notices_built:
		return
	_notices_built = true
	_label(_notices_box, "Hecho con Godot Engine " + str(Engine.get_version_info().get("string", "")), 19)
	_label(_notices_box, Engine.get_license_text(), 15)
	for info: Dictionary in Engine.get_copyright_info():
		var lines: Array[String] = [str(info.get("name", ""))]
		for part: Dictionary in info.get("parts", []):
			lines.append("© " + "; ".join(PackedStringArray(part.get("copyright", []))) + " — " + str(part.get("license", "")))
		_label(_notices_box, "\n".join(PackedStringArray(lines)), 14)
	_apply_theme()


func _wire_focus() -> void:
	for button in _buttons:
		Arcade.enable_pad_accept(button)
	for i in _buttons.size():
		var control := _buttons[i]
		control.focus_previous = control.get_path_to(_buttons[posmod(i - 1, _buttons.size())])
		control.focus_next = control.get_path_to(_buttons[(i + 1) % _buttons.size()])
		control.focus_neighbor_top = control.focus_previous
		control.focus_neighbor_bottom = control.focus_next
		control.focus_neighbor_left = NodePath(".")
		control.focus_neighbor_right = NodePath(".")
		control.focus_entered.connect(_scroll_to.bind(control))


func _scroll_to(control: Control) -> void:
	if control != _back:
		_scroll.ensure_control_visible(control)


func _apply_theme() -> void:
	_palette = GameState.active_theme()
	var accent := _palette.menu_accent
	_version_label.text = "Versión " + version_text()
	_shade.color = _palette.backdrop_color
	Arcade.panel(_panel, _palette, accent, 28)
	for label in _labels + _headings:
		Arcade.font(label, _palette)
		label.add_theme_color_override("font_color", _palette.text_color)
	for label in _headings:
		label.add_theme_color_override("font_color", accent.lightened(0.32))
	for button in _buttons:
		Arcade.button(button, _palette, accent, button == _back)
