@tool
extends StaticBody2D
## Naipe del banco: blanco fijo que se "da vuelta" al golpearlo. Solo avisa (`hit`) y se dibuja;
## el puntaje y el banco los lleva AliceRules.

## La bola golpeó el naipe (el índice 0..3 sale del nombre del nodo: Card0..Card3).
signal hit(index: int)

const SIZE := Vector2(44, 62)

var flipped := false
var index := 0


func _ready() -> void:
	index = clampi(name.trim_prefix("Card").to_int(), 0, 3)


func on_ball_contact(_ball: RigidBody2D, _state: PhysicsDirectBodyState2D, _point: Vector2) -> void:
	if GameState.playing:
		strike.call_deferred()


## Registra el golpe. Público para poder probarlo sin física.
func strike() -> void:
	if not GameState.playing:
		return
	Settings.vibrate(8)
	hit.emit(index)


## Da vuelta el naipe o lo vuelve a tapar (el banco lo apaga al completarse).
func set_flipped(value: bool) -> void:
	flipped = value
	queue_redraw()


func _draw() -> void:
	AliceVisuals.draw_card(self, index, flipped, SIZE)
