extends Control
## Entrada a las mesas. Las teclas y el mando navegan los mismos botones que el touch.

const Screen := preload("res://scripts/util/screen.gd")
const BackNav := preload("res://scripts/util/back_nav.gd")
const GameSave := preload("res://scripts/util/game_save.gd")
const DraculaCard := preload("res://scripts/ui/dracula_card.gd")
const AliceCard := preload("res://scripts/ui/alice_card.gd")
const NAUTILUS_PRINT := preload("res://assets/nautilus_playfield.webp")
const INK := Color("#071119")
const MINT := Color("#8cead2")
const GOLD := Color("#ffd397")
const IVORY := Color("#edf2df")

var _kernel: Button
var _nautilus: Button
var _dracula: Button
var _alicia: Button
var _records: Button
var _heading: FontVariation
var _serif: SystemFont
var _safe_top := 0.0
var _safe_bottom := 0.0
var _cards: Array[Button] = []
var _ids: Array[String] = []
var _selected := 0
var _display_index := 0.0
var _clock := 0.0
var _drag_start := Vector2.ZERO
var _dragging := false
var _swiped := false
var _previous: Button
var _next: Button


func _ready() -> void:
	GameState.leave_game()
	_heading = FontVariation.new()
	_heading.base_font = ThemeDB.fallback_font
	_heading.variation_embolden = 0.9
	_serif = SystemFont.new()
	_serif.font_names = PackedStringArray(["Noto Serif", "DejaVu Serif", "serif"])
	_serif.font_weight = 700
	_kernel = _make_card(GameState.active_theme(GameState.KERNEL_PANIC).display_name, GameState.KERNEL_PANIC, 432.0, "res://scenes/main.tscn")
	_nautilus = _make_card(GameState.active_theme(GameState.NAUTILUS).display_name, GameState.NAUTILUS, 646.0, "res://scenes/nautilus.tscn")
	_dracula = _make_card(GameState.active_theme(GameState.DRACULA).display_name, GameState.DRACULA, 444.0, "res://scenes/dracula.tscn")
	_alicia = _make_card(GameState.active_theme(GameState.ALICIA).display_name, GameState.ALICIA, 444.0, "res://scenes/alicia.tscn")
	_cards = [_kernel, _nautilus, _dracula, _alicia]
	_ids = [GameState.KERNEL_PANIC, GameState.NAUTILUS, GameState.DRACULA, GameState.ALICIA]
	_records = _make_records_button()
	_previous = _make_arrow("‹", -1)
	_next = _make_arrow("›", 1)
	get_viewport().size_changed.connect(_layout)
	_layout()
	_kernel.grab_focus()


func _make_arrow(label: String, direction: int) -> Button:
	var button := Button.new()
	button.text = label
	button.size = Vector2(72, 72)
	button.add_theme_font_size_override("font_size", 48)
	button.pressed.connect(func() -> void: _select(_selected + direction))
	add_child(button)
	return button


func _select(index: int) -> void:
	_selected = clampi(index, 0, _cards.size() - 1)
	_cards[_selected].grab_focus()
	queue_redraw()


func _activate_card(card: Button, scene_path: String) -> void:
	if _swiped:
		return
	var index := _cards.find(card)
	if index != _selected:
		_select(index)
	else:
		get_tree().change_scene_to_file(scene_path)


func _unhandled_input(event: InputEvent) -> void:
	if BackNav.is_back_event(event):
		get_viewport().set_input_as_handled()
		go_back()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()


## Atrás en el selector: vuelve al título.
func go_back() -> void:
	if BackNav.claim():
		get_tree().change_scene_to_file.call_deferred(BackNav.TITLE_SCENE)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		_select(_selected - 1)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_right"):
		_select(_selected + 1)
		get_viewport().set_input_as_handled()
		return
	var point := Vector2.ZERO
	var pressed := false
	var released := false
	if event is InputEventScreenTouch:
		point = event.position
		pressed = event.pressed
		released = not event.pressed
	elif event is InputEventScreenDrag:
		point = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		point = event.position
		pressed = event.pressed
		released = not event.pressed
	elif event is InputEventMouseMotion:
		point = event.position
	else:
		return
	if pressed:
		_drag_start = point
		_dragging = point.y > _safe_top + 180.0 and point.y < size.y - _safe_bottom - 100.0
		_swiped = false
	elif _dragging:
		if absf(point.x - _drag_start.x) > 55.0:
			_swiped = true
		if released:
			if _swiped:
				_select(_selected + (1 if point.x < _drag_start.x else -1))
			_dragging = false
			_clear_swipe.call_deferred()


func _clear_swipe() -> void:
	_swiped = false


func _process(delta: float) -> void:
	_clock += delta
	_display_index = lerpf(_display_index, float(_selected), minf(delta * 8.0, 1.0))
	_layout_cards()


func _make_records_button() -> Button:
	var button := Button.new()
	button.name = "Records"
	button.text = "Récords"
	button.size = Vector2(160, 44)
	button.add_theme_font_size_override("font_size", 23)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, IVORY)
	for state in ["normal", "hover", "pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = {"normal": Color("#101d24"), "hover": Color("#1d3a3d"), "pressed": Color("#12232a")}[state]
		box.border_color = MINT if state != "normal" else Color(MINT, 0.5)
		box.set_border_width_all(2)
		box.set_corner_radius_all(10)
		button.add_theme_stylebox_override(state, box)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = IVORY
	focus.set_border_width_all(3)
	focus.set_corner_radius_all(10)
	button.add_theme_stylebox_override("focus", focus)
	button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/records.tscn"))
	add_child(button)
	return button


func _make_card(title: String, table_id: String, height: float, scene_path: String) -> Button:
	var has_save := false
	if not GameState.save_directory.is_empty():
		has_save = not GameSave.load_run(table_id, GameState.save_directory).is_empty()
	var card := Button.new()
	card.name = {GameState.NAUTILUS: "Nautilus", GameState.DRACULA: "Dracula", GameState.ALICIA: "Alicia"}.get(table_id, "KernelPanic")
	card.text = title
	card.tooltip_text = "Continuar " + title if has_save else title
	card.size = Vector2(624, height)
	card.clip_contents = true
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var blank := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		card.add_theme_stylebox_override(state, blank)
	for state in ["font_color", "font_pressed_color", "font_hover_color", "font_focus_color", "font_hover_pressed_color", "font_outline_color"]:
		card.add_theme_color_override(state, Color.TRANSPARENT)
	card.draw.connect(_draw_card.bind(card, table_id, has_save))
	card.pressed.connect(_activate_card.bind(card, scene_path))
	add_child(card)
	return card


func _layout() -> void:
	var safe := Screen.safe_insets(get_viewport())
	_safe_top = safe.top
	_safe_bottom = safe.bottom
	_records.position = Vector2(size.x - _records.size.x - 24.0, _safe_top + 6.0)
	_previous.position = Vector2(18, size.y - _safe_bottom - 100)
	_next.position = Vector2(size.x - 90, size.y - _safe_bottom - 100)
	_layout_cards()
	queue_redraw()


func _layout_cards() -> void:
	if _cards.is_empty():
		return
	var available := size.y - _safe_top - _safe_bottom
	var center := Vector2(size.x * 0.5, _safe_top + available * 0.48)
	for i in _cards.size():
		var card := _cards[i]
		var offset := float(i) - _display_index
		var distance := absf(offset)
		card.visible = distance < 1.8
		var zoom := minf(size.x * 0.70 / card.size.x, available * 0.53 / card.size.y)
		zoom *= 1.0 - minf(distance, 1.0) * 0.32
		card.pivot_offset = card.size * 0.5
		card.scale = Vector2(zoom * (1.0 - minf(distance, 1.0) * 0.18), zoom)
		card.rotation = offset * -0.12 + sin(_clock * 1.3 + float(i)) * 0.015
		card.position = center + Vector2(offset * size.x * 0.36, distance * 35.0) - card.pivot_offset
		card.z_index = 10 - int(distance * 4.0)
		card.queue_redraw()


func _draw() -> void:
	if _heading == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), INK)
	for y in range(0, int(size.y), 6):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.41, 0.61, 0.62, 0.05))
	var at := Vector2(size.x * 0.5, _safe_top + 94)
	_center_text(self, _heading, "PINBALL TEMÁTICO", at, 49, IVORY)
	_center_text(self, ThemeDB.fallback_font, "Elegí una mesa", at + Vector2(0, 49), 27, MINT)
	var record := _selected_record()
	var accent := GameState.active_theme(_ids[_selected]).select_accent
	_center_text(self, _heading, "RÉCORD  %d" % record, Vector2(size.x * 0.5, size.y - _safe_bottom - 145), 30, accent)
	_center_text(self, ThemeDB.fallback_font, "Deslizá o usá las flechas · Tocá para jugar", Vector2(size.x * 0.5, size.y - _safe_bottom - 55), 20, IVORY)
	var dash := Vector2(91, 0)
	draw_line(at + Vector2(-274, 38), at + Vector2(-274, 38) + dash, Color(MINT, 0.45), 1, true)
	draw_line(at + Vector2(274, 38), at + Vector2(274, 38) - dash, Color(MINT, 0.45), 1, true)


func _selected_record() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(GameState.record_path) != OK:
		return 0
	var section := "records" if _ids[_selected] == GameState.KERNEL_PANIC else "records/" + _ids[_selected]
	return int(cfg.get_value(section, "high_score", 0))


func _draw_card(card: Button, table_id: String, has_save: bool) -> void:
	var nautical := table_id == GameState.NAUTILUS
	var vampiric := table_id == GameState.DRACULA
	var wonderland := table_id == GameState.ALICIA
	var bounds := Rect2(Vector2.ZERO, card.size)
	var theme := GameState.active_theme(table_id)
	var accent := theme.select_accent
	var active := _cards.size() > _selected and card == _cards[_selected]
	card.draw_rect(bounds, Color("#12232a") if active else Color("#101d24"))
	var illustration := Rect2(7, 7, bounds.size.x - 14, 416 if nautical else (214 if (vampiric or wonderland) else 242))
	if nautical:
		var texture_size := NAUTILUS_PRINT.get_size()
		var crop := Rect2(0, 42, texture_size.x, texture_size.x * illustration.size.y / illustration.size.x)
		card.draw_texture_rect_region(NAUTILUS_PRINT, illustration, crop, Color("#f0eee4"))
	elif vampiric:
		DraculaCard.draw(card, illustration)
	elif wonderland:
		AliceCard.draw(card, illustration)
	else:
		_draw_kernel(card, illustration)
	if has_save:
		var tag := Rect2(illustration.end.x - 176, illustration.position.y + 15, 158, 41)
		card.draw_rect(tag, Color("#101b21"))
		card.draw_rect(tag, Color(accent, 0.8), false, 2, true)
		_center_text(card, _heading, "Continuar", tag.get_center() + Vector2(0, 7), 22, IVORY)
	var text_start := illustration.end.y
	card.draw_line(Vector2(17, text_start), Vector2(bounds.end.x - 17, text_start), Color(accent, 0.64), 2, true)
	var headline := card.text
	var subtitle := theme.subtitle
	var summary := theme.summary
	var left := 29.0
	var font := ThemeDB.fallback_font
	card.draw_string(_serif if (nautical or vampiric or wonderland) else _heading, Vector2(left, text_start + 64),
		headline, HORIZONTAL_ALIGNMENT_LEFT, -1, 50 if (nautical or vampiric or wonderland) else 46, accent)
	card.draw_string(_heading, Vector2(left, text_start + 103),
		subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 27, IVORY)
	card.draw_string(font, Vector2(left, text_start + 143),
		summary, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("#a9c0c1"))
	if not theme.tagline.is_empty():
		card.draw_string(font, Vector2(left, text_start + 181), theme.tagline,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#a9c0c1"))
	var arrow := Vector2(bounds.end.x - 49, text_start + 79)
	card.draw_circle(arrow, 23, Color(accent, 0.18 if active else 0.08), true, -1, true)
	card.draw_polyline(PackedVector2Array([arrow + Vector2(-4, -8), arrow + Vector2(4, 0), arrow + Vector2(-4, 8)]),
		accent, 3, true)
	card.draw_rect(bounds.grow(-2), Color(accent, 0.92 if active else 0.43), false, 2, true)


func _draw_kernel(card: Button, rect: Rect2) -> void:
	card.draw_rect(rect, Color("#0a2229"))
	var center := rect.get_center()
	for y in range(int(rect.position.y) + 2, int(rect.end.y), 5):
		card.draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color(MINT, 0.065))
	for side in [-1, 1]:
		for row in range(-2, 3):
			var a := center + Vector2(side * 77, row * 16)
			var b := a + Vector2(side * (53 + 10 * absi(row)), 0)
			var c := b + Vector2(side * 43, row * 17)
			var d := c + Vector2(side * (57 - absi(row) * 18), 0)
			card.draw_polyline(PackedVector2Array([a, b, c, d]), Color(MINT, 0.43), 2, true)
			card.draw_circle(d, 4, Color(MINT, 0.6), false, 1.4, true)
	var core := Rect2(center - Vector2(75, 64), Vector2(150, 128))
	card.draw_rect(core.grow(7), Color("#081619"))
	card.draw_rect(core, Color("#173d41"))
	card.draw_rect(core, Color(MINT, 0.62), false, 2, true)
	card.draw_rect(core.grow(-10), Color("#0a2028"))
	_center_text(card, _heading, ">_", center + Vector2(0, 23), 56, MINT)
	for i in 8:
		var x := core.position.x + 12.0 + i * 18
		card.draw_line(Vector2(x, core.position.y - 11), Vector2(x, core.position.y), GOLD.darkened(0.32), 2, true)
		card.draw_line(Vector2(x, core.end.y), Vector2(x, core.end.y + 11), GOLD.darkened(0.32), 2, true)


func _center_text(canvas: CanvasItem, font: Font, title: String, at: Vector2, font_size: int, tint: Color) -> void:
	var width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	canvas.draw_string(font, at - Vector2(width * 0.5, 0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, tint)
