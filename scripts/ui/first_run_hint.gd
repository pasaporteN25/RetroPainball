extends CanvasLayer
## Indicación breve que se registra por separado de partidas y récords.

@export var settings_path := "user://settings.cfg"
@export var duration := 6.0
var _panel: PanelContainer
var _remaining := 0.0


func _ready() -> void:
	layer = 11
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var config := ConfigFile.new()
	if config.load(settings_path) == OK and config.get_value("tutorial", "first_run_seen", false):
		return
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.offset_left = -300
	_panel.offset_right = 300
	_panel.offset_top = -270
	_panel.offset_bottom = -170
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#172321")
	style.border_color = Color("#507267")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	var label := Label.new()
	label.text = "Tocá la mitad izquierda o derecha para los flippers.\nMantené el botón de lanzar y soltá."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color("#f3ead8"))
	_panel.add_child(label)
	_remaining = duration
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(settings_path.get_base_dir()))
	config.set_value("tutorial", "first_run_seen", true)
	config.save(settings_path)


func _process(delta: float) -> void:
	if _panel and _panel.visible:
		_remaining -= delta
		if _remaining <= 0.0:
			_panel.hide()


func on_launched(_power: float) -> void:
	if _panel:
		_panel.hide()
