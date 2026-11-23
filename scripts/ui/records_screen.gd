extends Control
## Pantalla de récords: el top 10 de cada mesa. Se abre desde el selector de mesas.

const Arcade := preload("res://scripts/ui/arcade_style.gd")
const Records := preload("res://scripts/util/records.gd")
const TABLE_IDS := [GameState.KERNEL_PANIC, GameState.NAUTILUS, GameState.DRACULA, GameState.ALICIA]
const STAT_LABELS := ["PARTIDAS", "MEJOR BOLA", "JACKPOTS"]
const STAT_KEYS := ["games", "best_ball", "jackpots"]

var table_id := GameState.KERNEL_PANIC
## [id, nombre, acento] de cada mesa, tomados de su TableTheme (S-01).
var _tables: Array = []
var _tabs: Array[Button] = []
var _rows: Array[HBoxContainer] = []
var _stat_names: Array[Label] = []
var _stat_values: Array[Label] = []
var _palette: TableTheme
var _shade: ColorRect
var _title: Label
var _panel: PanelContainer
var _stats_panel: PanelContainer
var _heading: HBoxContainer
var _back: Button
var _empty: Label


func _ready() -> void:
	GameState.leave_game()
	for id: String in TABLE_IDS:
		var palette := GameState.active_theme(id)
		_tables.append([id, palette.display_name, palette.records_accent])
	if GameState.table_id in TABLE_IDS:
		table_id = GameState.table_id
	_shade = ColorRect.new()
	add_child(_shade)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Arcade.center_in_safe_area(center)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size.x = 648
	center.add_child(_panel)
	get_viewport().size_changed.connect(func() -> void: Arcade.center_in_safe_area(_panel.get_parent()))
	_panel.draw.connect(func() -> void: Arcade.draw_trim(_panel, _palette.records_accent))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_panel.add_child(column)
	_title = _label("", 48, HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(_title)
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 10)
	column.add_child(tab_row)
	for entry: Array in _tables:
		var tab := Button.new()
		tab.name = String(entry[0])
		tab.text = entry[1]
		tab.custom_minimum_size.y = 56
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.add_theme_font_size_override("font_size", 18)
		tab.pressed.connect(show_table.bind(entry[0]))
		Arcade.enable_pad_accept(tab)
		tab_row.add_child(tab)
		_tabs.append(tab)

	var leaderboard := VBoxContainer.new()
	leaderboard.add_theme_constant_override("separation", 3)
	column.add_child(leaderboard)
	_heading = _score_row(leaderboard, 32, 16, ["PUESTO", "INICIALES", "PUNTAJE"])
	for rank in Records.MAX_ENTRIES:
		_rows.append(_score_row(leaderboard, 43, 26, ["%d" % (rank + 1), "", ""]))
	_empty = _label("Todavía no hay récords en esta mesa", 20, HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(_empty)
	_build_stats(column)
	_back = Button.new()
	_back.name = "Back"
	_back.text = "Volver"
	_back.custom_minimum_size.y = 68
	_back.add_theme_font_size_override("font_size", 27)
	_back.pressed.connect(_close)
	Arcade.enable_pad_accept(_back)
	column.add_child(_back)
	for i in _tabs.size():
		var tab := _tabs[i]
		tab.focus_neighbor_left = tab.get_path_to(_tabs[posmod(i - 1, _tabs.size())])
		tab.focus_neighbor_right = tab.get_path_to(_tabs[(i + 1) % _tabs.size()])
		tab.focus_neighbor_top = tab.get_path_to(_back)
		tab.focus_neighbor_bottom = tab.focus_neighbor_top
	_back.focus_neighbor_left = NodePath(".")
	_back.focus_neighbor_right = NodePath(".")
	show_table(table_id)
	_back.grab_focus()


func show_table(id: String) -> void:
	table_id = id
	_palette = GameState.active_theme(id)
	var accent := _palette.records_accent
	_shade.color = Color(_palette.backdrop_color, 1.0)
	Arcade.panel(_panel, _palette, accent, 28)
	_title.text = _palette.records_title
	_tint(_title, _palette.text_color)
	_tint(_empty, _palette.muted_color)
	for i in _tables.size():
		var selected: bool = _tables[i][0] == id
		Arcade.button(_tabs[i], _palette, _tables[i][2], selected)
		if selected:
			_back.focus_neighbor_top = _back.get_path_to(_tabs[i])
			_back.focus_neighbor_bottom = _back.focus_neighbor_top
	Arcade.button(_back, _palette, accent, true)
	for label: Label in _heading.get_children():
		_tint(label, _palette.muted_color)

	var top := GameState.top_scores(Records.key(id, GameState.record_variant))
	for i in _rows.size():
		var row := _rows[i]
		var filled := i < top.size()
		var leader := i == 0 and filled
		var fill := _palette.panel_ink_color.lerp(accent, 0.16 if leader else (0.04 if i % 2 == 0 else 0.0))
		var edge := accent.darkened(0.27) if leader else Color(_palette.panel_frame_color, 0.37)
		var style := Arcade.box(fill, edge, 7)
		style.content_margin_left = 14
		style.content_margin_right = 14
		var surface := row.get_parent() as PanelContainer
		surface.add_theme_stylebox_override("panel", style)
		var initials: Label = row.get_child(1)
		initials.text = top[i]["initials"] if filled else "---"
		var score: Label = row.get_child(2)
		score.text = _format(int(top[i]["score"])) if filled else "·"
		for label: Label in row.get_children():
			var tint := _palette.text_color if filled else _palette.muted_color.darkened(0.24)
			_tint(label, accent.lightened(0.42) if leader else tint)
	_empty.visible = top.is_empty()
	_update_stats()


func _score_row(parent: VBoxContainer, height: float, font_size: int, texts: Array[String]) -> HBoxContainer:
	var surface := PanelContainer.new()
	surface.custom_minimum_size.y = height
	var style := StyleBoxEmpty.new()
	style.content_margin_left = 14
	style.content_margin_right = 14
	surface.add_theme_stylebox_override("panel", style)
	parent.add_child(surface)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	surface.add_child(row)
	for i in texts.size():
		var label := _label(texts[i], font_size, HORIZONTAL_ALIGNMENT_RIGHT if i == 2 else HORIZONTAL_ALIGNMENT_CENTER)
		row.add_child(label)
		if i == 2:
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		else:
			label.custom_minimum_size.x = 72 if i == 0 else 106
	return row


func _build_stats(parent: VBoxContainer) -> void:
	_stats_panel = PanelContainer.new()
	parent.add_child(_stats_panel)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 0)
	_stats_panel.add_child(line)
	for title in STAT_LABELS:
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_constant_override("separation", 2)
		line.add_child(cell)
		var caption := _label(title, 16, HORIZONTAL_ALIGNMENT_CENTER)
		var value := _label("", 25, HORIZONTAL_ALIGNMENT_CENTER)
		cell.add_child(caption)
		cell.add_child(value)
		_stat_names.append(caption)
		_stat_values.append(value)
	line.draw.connect(func() -> void:
		for i in [1, 2]:
			var x := line.size.x * float(i) / 3.0
			line.draw_line(Vector2(x, 4), Vector2(x, line.size.y - 4), _palette.panel_frame_color, 1.0, true))


func _update_stats() -> void:
	var stats := GameState.table_stats(table_id)
	var style := Arcade.box(_palette.panel_ink_color.darkened(0.23), _palette.panel_frame_color)
	style.set_content_margin_all(10)
	_stats_panel.add_theme_stylebox_override("panel", style)
	_stats_panel.get_child(0).queue_redraw()
	for i in STAT_KEYS.size():
		_tint(_stat_names[i], _palette.muted_color)
		var value := _stat_values[i]
		var number := int(stats[STAT_KEYS[i]])
		value.text = _format(number) if i == 1 else str(number)
		_tint(value, _palette.records_accent.lightened(0.42))
		var font := value.get_theme_font("font")
		var width := font.get_string_size(value.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 25).x
		value.add_theme_font_size_override("font_size", mini(25, floori(25.0 * 178.0 / maxf(1.0, width))))


## Línea de estadísticas de la mesa: partidas, mejor bola y jackpots (U-09).
func stats_text(id: String) -> String:
	var stats := GameState.table_stats(id)
	return "Partidas %d   ·   Mejor bola %s   ·   Jackpots %d" % [
		stats["games"], _format(int(stats["best_ball"])), stats["jackpots"]]


func row_texts() -> Array[String]:
	var texts: Array[String] = []
	for row in _rows:
		var rank: Label = row.get_child(0)
		var initials: Label = row.get_child(1)
		var score: Label = row.get_child(2)
		texts.append("%2d   %s   %s" % [int(rank.text), initials.text, score.text])
	return texts


func _close() -> void:
	get_tree().change_scene_to_file("res://scenes/table_select.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()


func _label(text: String, size: int, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	return label


func _tint(label: Label, color: Color) -> void:
	Arcade.font(label, _palette)
	label.add_theme_color_override("font_color", color)


func _format(n: int) -> String:
	var text := str(n)
	var suffix := ""
	while text.length() > 3:
		suffix = "." + text.substr(text.length() - 3) + suffix
		text = text.substr(0, text.length() - 3)
	return text + suffix
