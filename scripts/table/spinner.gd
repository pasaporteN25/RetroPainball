extends Area2D
## G-10: spinner genérico. La bola lo atraviesa y lo hace girar: la velocidad de giro es
## proporcional a la velocidad de la bola al entrar (TableRules.spinner_spin_per_speed) y el
## sentido sale de hacia dónde avanza respecto de `lane_direction`. Cada vuelta completa suma
## TableRules.spinner_lap_points. No frena ni desvía la bola. Se ajusta desde el inspector.
## Si el Area2D no trae un CollisionShape2D, se crea uno rectangular de `length` x 14.

const Ball := preload("res://scripts/table/ball.gd")
const BRASS := Color("#bf8c55")
const GOLD := Color("#ffe0ac")

## Cada vez que se completa una vuelta; `total` cuenta las vueltas desde que se creó la pieza.
signal lap_completed(total: int)

## Largo de la paleta en px.
@export var length := 60.0
## Frenado del giro en rad/s por segundo.
@export var friction := 6.0
## Eje del carril: la bola que avanza en este sentido hace girar en positivo.
@export var lane_direction := Vector2.UP

## Lo prende la regla de la mesa (p. ej. sudo en Kernel Panic): la paleta se dibuja dorada.
var lit := false
var spin_speed := 0.0
var laps := 0
var _angle := 0.0
var _progress := 0.0


func _ready() -> void:
	collision_mask |= 2
	if find_children("*", "CollisionShape2D", false).is_empty():
		var shape := RectangleShape2D.new()
		shape.size = Vector2(length, 14.0)
		var owner_shape := CollisionShape2D.new()
		owner_shape.shape = shape
		add_child(owner_shape)
	body_entered.connect(_on_body_entered)
	set_process(false)


func _on_body_entered(body: Node2D) -> void:
	var ball := body as Ball
	if ball != null:
		kick_spin(ball.linear_velocity)


## Empuja el spinner con la velocidad `velocity` de una bola. Solo pisa el giro si es mayor o de sentido contrario.
func kick_spin(velocity: Vector2) -> void:
	var along := velocity.dot(lane_direction.normalized())
	var target := velocity.length() * GameState.active_rules().spinner_spin_per_speed
	target *= 1.0 if along >= 0.0 else -1.0
	if absf(target) > absf(spin_speed) or signf(target) != signf(spin_speed):
		spin_speed = target
	Sfx.play(&"flipper", 1.4)
	set_process(true)


func _process(delta: float) -> void:
	if is_zero_approx(spin_speed):
		set_process(false)
		queue_redraw()
		return
	var step := spin_speed * delta
	_angle = fposmod(_angle + step, TAU)
	_progress += absf(step)
	while _progress >= TAU:
		_progress -= TAU
		laps += 1
		GameState.add_score(GameState.active_rules().spinner_lap_points, global_position)
		lap_completed.emit(laps)
	spin_speed = move_toward(spin_speed, 0.0, friction * delta)
	queue_redraw()


func _draw() -> void:
	var half := length * 0.5
	draw_line(Vector2(0, -half - 4), Vector2(0, half + 4), BRASS.darkened(0.4), 4.0, true)
	# Vista en perspectiva de la paleta: el ancho visible sigue al coseno del ángulo.
	var width := absf(cos(_angle)) * 9.0 + 1.5
	draw_line(Vector2(-width, 0), Vector2(width, 0), GOLD if lit else GOLD.lerp(BRASS, 0.5), 4.0, true)
	draw_circle(Vector2(0, -half), 3.0, BRASS, true, -1.0, true)
	draw_circle(Vector2(0, half), 3.0, BRASS, true, -1.0, true)
