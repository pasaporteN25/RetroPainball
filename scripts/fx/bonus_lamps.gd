extends Node2D
## Indicador del multiplicador de la bola actual, sobre el arte del tablero.

const InsertLamp := preload("res://scripts/fx/insert_lamp.gd")

var lit_count := 0
var _last_multiplier := 0
var _tint := Color("#83ff91")


func _ready() -> void:
	if GameState.table_id == "nautilus":
		_tint = Color("#78e4db")
	GameState.bonus_awarded.connect(_on_bonus_awarded)
	GameState.game_started.connect(_sync_multiplier)
	GameState.game_resumed.connect(_sync_multiplier)
	_sync_multiplier()


func _process(_delta: float) -> void:
	if GameState.bonus_multiplier != _last_multiplier:
		_sync_multiplier()


func _sync_multiplier() -> void:
	_last_multiplier = GameState.bonus_multiplier
	lit_count = clampi(_last_multiplier, 1, GameState.MAX_MULTIPLIER)
	queue_redraw()


func _on_bonus_awarded(_base: int, _multiplier: int, _total: int) -> void:
	_last_multiplier = GameState.bonus_multiplier
	lit_count = 0
	queue_redraw()


func _draw() -> void:
	for i in GameState.MAX_MULTIPLIER:
		InsertLamp.draw(self, Vector2((i - 2) * 22, 0), 6.0, _tint, 1.0 if i < lit_count else 0.0)
