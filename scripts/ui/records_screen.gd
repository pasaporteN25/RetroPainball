extends Control
## Pantalla de récords: el top 10 de cada mesa. Se abre desde el selector de mesas.

const Screen := preload("res://scripts/util/screen.gd")
const Records := preload("res://scripts/util/records.gd")
const INK := Color("#071119")
const MINT := Color("#75e6c6")
const AMBER := Color("#ffbc6b")
const IVORY := Color("#f3ead8")
const STEEL := Color("#a7b5b9")
const FRAME := Color("#435052")
const TABLE_IDS := [GameState.KERNEL_PANIC, GameState.NAUTILUS, GameState.DRACULA, GameState.ALICIA]

var table_id := GameState.KERNEL_PANIC
## [id, nombre, acento] de cada mesa, tomados de su TableTheme (S-01).
var _tables: Array = []
var _tabs: Array[Button] = []
var _rows: Array[Label] = []
var _title: Label
var _panel: PanelContainer
var _back: Button
var _empty: Label
var _stats: Label


func _ready() -> void:
	GameState.leave_game()
	for id: String in TABLE_IDS:
		var theme := GameState.active_theme(id)
		_tables.append([id, theme.display_name, theme.records_accent])
	if _tables.any(func(t: Array) -> bool: return t[0] == GameState.table_id):
		table_id = GameState.table_id
	var shade := ColorRect.new()
	shade.color = INK
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(560, 0)
	_panel.add_theme_stylebox_override("panel", _box(Color("#101619"), 18, FRAME, 28))
	center.add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	_panel.add_child(column)
	_title = _label(GameState.active_theme().records_title, 48, IVORY, HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(_title)
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 8)
	column.add_child(tab_row)
	for entry: Array in _tables:
		var tab := Button.new()
		tab.name = String(entry[0])
		tab.text = entry[1]
		tab.custom_minimum_size = Vector2(160, 56)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.add_theme_font_size_override("font_size", 19)
		tab.pressed.connect(show_table.bind(entry[0]))
		tab_row.add_child(tab)
		_tabs.append(tab)
	for i in _tabs.size():
		_tabs[i].focus_neighbor_left = _tabs[(i + _tabs.size() - 1) % _tabs.size()].get_path()
		_tabs[i].focus_neighbor_right = _tabs[(i + 1) % _tabs.size()].get_path()
	for rank in Records.MAX_ENTRIES:
		var row := _label("", 28, IVORY, HORIZONTAL_ALIGNMENT_LEFT)
		row.custom_minimum_size = Vector2(0, 46)
		column.add_child(row)
		_rows.append(row)
	_empty = _label("Todavía no hay récords en esta mesa", 20, STEEL, HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(_empty)
	_stats = _label("", 22, STEEL, HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(_stats)
	_back = Button.new()
	_back.name = "Back"
	_back.text = "Volver"
	_back.custom_minimum_size = Vector2(0, 66)
	_back.add_theme_font_size_override("font_size", 27)
	_style_button(_back, MINT, true)
	_back.pressed.connect(_close)
	column.add_child(_back)
	for tab in _tabs:
		tab.focus_neighbor_bottom = tab.get_path_to(_back)
	_back.focus_neighbor_top = _back.get_path_to(_tabs[0])
	show_table(table_id)
	_back.grab_focus()


func show_table(id: String) -> void:
	table_id = id
	var accent := MINT
	for i in _tables.size():
		var selected: bool = _tables[i][0] == id
		if selected:
			accent = _tables[i][2]
		_style_button(_tabs[i], _tables[i][2], selected)
	var top := GameState.top_scores(Records.key(id, GameState.record_variant))
	for i in _rows.size():
		var row := _rows[i]
		if i < top.size():
			row.text = "%2d   %s   %s" % [i + 1, top[i]["initials"], _format(int(top[i]["score"]))]
			row.add_theme_color_override("font_color", accent if i == 0 else IVORY)
		else:
			row.text = "%2d   ---   ·" % [i + 1]
			row.add_theme_color_override("font_color", STEEL.darkened(0.45))
	_empty.visible = top.is_empty()
	_stats.text = stats_text(id)


## Línea de estadísticas de la mesa: partidas, mejor bola y jackpots (U-09).
func stats_text(id: String) -> String:
	var stats := GameState.table_stats(id)
	return "Partidas %d   ·   Mejor bola %s   ·   Jackpots %d" % [
		stats["games"], _format(int(stats["best_ball"])), stats["jackpots"]]


func row_texts() -> Array[String]:
	var texts: Array[String] = []
	for row in _rows:
		texts.append(row.text)
	return texts


func _close() -> void:
	get_tree().change_scene_to_file("res://scenes/table_select.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()


func _label(text: String, size: int, tint: Color, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", tint)
	return label


func _style_button(button: Button, accent: Color, filled: bool) -> void:
	var text_color := Color("#111b1b") if filled else IVORY
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, text_color)
	if filled:
		button.add_theme_stylebox_override("normal", _box(accent, 10, accent.lightened(0.32)))
		button.add_theme_stylebox_override("hover", _box(accent.lightened(0.22), 10, accent.lightened(0.46)))
		button.add_theme_stylebox_override("pressed", _box(accent.darkened(0.22), 10, accent))
	else:
		button.add_theme_stylebox_override("normal", _box(Color("#172321"), 10, accent.darkened(0.4)))
		button.add_theme_stylebox_override("hover", _box(Color("#253936"), 10, accent))
		button.add_theme_stylebox_override("pressed", _box(Color("#1b272b"), 10, accent))
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = IVORY
	focus.set_border_width_all(4)
	focus.set_corner_radius_all(10)
	focus.set_expand_margin_all(4)
	button.add_theme_stylebox_override("focus", focus)


func _box(color: Color, radius: int, border := Color.TRANSPARENT, margin := 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	if border.a > 0.0:
		box.border_color = border
		box.set_border_width_all(2)
	if margin > 0:
		box.set_content_margin_all(margin)
	return box


func _format(n: int) -> String:
	var text := str(n)
	var suffix := ""
	while text.length() > 3:
		suffix = "." + text.substr(text.length() - 3) + suffix
		text = text.substr(0, text.length() - 3)
	return text + suffix
